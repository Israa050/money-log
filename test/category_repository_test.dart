import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockflow/core/result.dart';
import 'package:stockflow/transactions/data/repos/category_repository_impl.dart';
import 'package:stockflow/transactions/data/repos/transactions_repository_impl.dart';
import 'package:stockflow/transactions/data/transactions_data_source.dart';
import 'package:stockflow/transactions/domain/entities/transaction_type.dart';
import 'package:uuid/uuid.dart';

// Every test here runs against a fresh in-memory database that already
// contains the 4 seeded default categories from onCreate (unlike
// transactions, which starts empty) -- assertions filter to the category
// created within the test rather than assuming an empty table.
void main() {
  late TransactionsDataSource dataSource;
  late CategoryRepositoryImpl repository;
  late TransactionsRepositoryImpl transactionsRepository;

  setUp(() {
    dataSource = TransactionsDataSource(NativeDatabase.memory());
    repository = CategoryRepositoryImpl(dataSource: dataSource);
    transactionsRepository = TransactionsRepositoryImpl(dataSource: dataSource);
  });

  tearDown(() async {
    await dataSource.close();
  });

  group('addCategory', () {
    test(
      'valid name -> Success, and the category is readable via watchCategories after.',
      () async {
        final result = await repository.addCategory(name: 'Groceries');
        expect(result, isA<Success<void>>());

        final categories = await repository.watchCategories().first;
        expect(categories.any((c) => c.name == 'Groceries'), isTrue);
      },
    );

    test('colorHex provided -> round-trips unchanged.', () async {
      await repository.addCategory(name: 'Groceries', colorHex: '#123456');

      final categories = await repository.watchCategories().first;
      final added = categories.singleWhere((c) => c.name == 'Groceries');
      expect(added.colorHex, '#123456');
    });

    test('colorHex omitted -> stored as null.', () async {
      await repository.addCategory(name: 'Groceries');

      final categories = await repository.watchCategories().first;
      final added = categories.singleWhere((c) => c.name == 'Groceries');
      expect(added.colorHex, null);
    });

    test('name is trimmed before being stored.', () async {
      await repository.addCategory(name: '  Groceries  ');

      final categories = await repository.watchCategories().first;
      expect(categories.any((c) => c.name == 'Groceries'), isTrue);
    });

    test('empty name -> Failure, no row created.', () async {
      final result = await repository.addCategory(name: '   ');

      expect(result, isA<Failure<void>>());
      final categories = await repository.watchCategories().first;
      expect(categories.length, 4); // only the seeded defaults
    });

    test(
      'duplicate name (case-insensitive) -> Failure, no row created.',
      () async {
        await repository.addCategory(name: 'Groceries');

        final result = await repository.addCategory(name: 'groceries');

        expect(result, isA<Failure<void>>());
        final categories = await repository.watchCategories().first;
        expect(categories.where((c) => c.name == 'Groceries').length, 1);
      },
    );

    test(
      'each call generates a distinct id -> two different names produce two rows.',
      () async {
        await repository.addCategory(name: 'Groceries');
        await repository.addCategory(name: 'Utilities');

        final categories = await repository.watchCategories().first;
        final groceries = categories.singleWhere((c) => c.name == 'Groceries');
        final utilities = categories.singleWhere((c) => c.name == 'Utilities');
        expect(groceries.id, isNot(utilities.id));
      },
    );
  });

  group('updateCategory', () {
    test('valid update -> Success, name and colorHex change.', () async {
      await repository.addCategory(name: 'Groceries', colorHex: '#111111');
      final id = (await repository.getCategoryByName('Groceries'))!.id;

      final result = await repository.updateCategory(
        id: id,
        name: 'Snacks',
        colorHex: '#222222',
      );

      expect(result, isA<Success<void>>());
      final categories = await repository.watchCategories().first;
      final updated = categories.singleWhere((c) => c.id == id);
      expect(updated.name, 'Snacks');
      expect(updated.colorHex, '#222222');
    });

    test(
      'keeping its own name -> Success, not treated as a duplicate.',
      () async {
        await repository.addCategory(name: 'Groceries', colorHex: '#111111');
        final id = (await repository.getCategoryByName('Groceries'))!.id;

        final result = await repository.updateCategory(
          id: id,
          name: 'Groceries',
          colorHex: '#222222',
        );

        expect(result, isA<Success<void>>());
      },
    );

    test("renaming to another category's existing name -> Failure.", () async {
      await repository.addCategory(name: 'Groceries');
      await repository.addCategory(name: 'Utilities');
      final utilitiesId = (await repository.getCategoryByName('Utilities'))!.id;

      final result = await repository.updateCategory(
        id: utilitiesId,
        name: 'Groceries',
      );

      expect(result, isA<Failure<void>>());
    });

    test('empty name -> Failure, existing row unchanged.', () async {
      await repository.addCategory(name: 'Groceries', colorHex: '#111111');
      final id = (await repository.getCategoryByName('Groceries'))!.id;

      final result = await repository.updateCategory(id: id, name: '   ');

      expect(result, isA<Failure<void>>());
      final categories = await repository.watchCategories().first;
      expect(categories.singleWhere((c) => c.id == id).name, 'Groceries');
    });
  });

  group('deleteCategory', () {
    test(
      'existing id -> Success(1), category no longer present afterward.',
      () async {
        await repository.addCategory(name: 'Groceries');
        final id = (await repository.getCategoryByName('Groceries'))!.id;

        final result = await repository.deleteCategory(id);

        expect(result, isA<Success<int>>());
        expect((result as Success<int>).data, 1);
        final categories = await repository.watchCategories().first;
        expect(categories.where((c) => c.id == id), isEmpty);
      },
    );

    test('non-existent id -> Success(0), not a Failure.', () async {
      final result = await repository.deleteCategory(const Uuid().v4());

      expect(result, isA<Success<int>>());
      expect((result as Success<int>).data, 0);
    });

    test(
      'deleting a category with transactions orphans them into '
      '"Uncategorized" in watchCategoryTotals, instead of failing.',
      () async {
        await repository.addCategory(name: 'Groceries', colorHex: '#111111');
        final id = (await repository.getCategoryByName('Groceries'))!.id;
        await transactionsRepository.addTransaction(
          amountMinor: 500,
          type: TransactionType.expense,
          categoryId: id,
        );

        final result = await repository.deleteCategory(id);
        expect(result, isA<Success<int>>());

        final totals = await repository.watchCategoryTotals().first;
        final uncategorized = totals.singleWhere(
          (t) => t.id == 'Uncategorized',
        );
        expect(uncategorized.totalMinor, 500);
      },
    );
  });

  group('watchCategories', () {
    test('a fresh repository already exposes the 4 seeded defaults.', () async {
      final categories = await repository.watchCategories().first;
      expect(categories.map((c) => c.name), [
        'Food',
        'Transport',
        'Shopping',
        'Bills',
      ]);
    });

    test(
      'is reactive -- emits again when a category is added after subscribing.',
      () async {
        expectLater(
          repository.watchCategories(),
          emitsInOrder([
            predicate<List>((list) => list.length == 4),
            predicate<List>((list) => list.length == 5),
          ]),
        );
        await Future<void>.delayed(Duration.zero);
        await repository.addCategory(name: 'Groceries');
      },
    );
  });

  group('getCategoryByName', () {
    test('existing name -> returns the matching entity.', () async {
      final result = await repository.getCategoryByName('Food');
      expect(result?.name, 'Food');
    });

    test('no matching name -> returns null.', () async {
      final result = await repository.getCategoryByName('Nonexistent');
      expect(result, null);
    });
  });
}
