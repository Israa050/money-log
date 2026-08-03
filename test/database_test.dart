

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockflow/transactions/data/models/transactions.dart';
import 'package:stockflow/transactions/data/transactions_data_source.dart';
import 'package:uuid/uuid.dart';

void main(){

  late TransactionsDataSource dataSource;

  setUp((){
    dataSource = TransactionsDataSource(NativeDatabase.memory());
  });

  tearDown(() async {
    await dataSource.close();
  });

    TransactionsCompanion buildEntry({
    required String id,
    int amountMinor = 100,
    TransactionType type = TransactionType.expense,
    Value<String?> note = const Value.absent(),
    Value<DateTime> occuredTime = const Value.absent(),
  }) {
    return TransactionsCompanion.insert(
      id: id,
      amountMinor: amountMinor,
      type: type,
      note: note,
      occuredTime: occuredTime,
    );
  }

  group('Test Drift', (){


     group('addTransaction', () {
    test('basic insert + read-back via allTransactions', ()async{
      String id = Uuid().v4();
        await dataSource.addTransaction(buildEntry(
          id: id,
          amountMinor: 50,
          note: Value('Some note'),
          type: TransactionType.expense,
          occuredTime: Value(DateTime.now()),
        ));
        final result = await dataSource.allTransactions;
        expect(result[0].id, id);
        expect(result[0].amountMinor, 50);
        expect(result[0].note, 'Some note');
        expect(result[0].type, TransactionType.expense);
    });
     test('note omitted -> stored as null', ()async{
      String id = Uuid().v4();
        await dataSource.addTransaction(buildEntry(
          id: id,
          amountMinor: 50,
          type: TransactionType.expense,
          occuredTime: Value(DateTime.now()),
        ));
        final result = await dataSource.allTransactions;
        expect(result[0].note, null);
    });

    test('occuredTime and creationTime auto-populate when omitted', () async {
      final before = DateTime.now();
      final id = const Uuid().v4();
      await dataSource.addTransaction(buildEntry(id: id));
      final after = DateTime.now();

      final result = (await dataSource.allTransactions).single;
      expect(result.occuredTime.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(result.occuredTime.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      expect(result.creationTime.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(result.creationTime.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('explicit occuredTime overrides the default (backdating)', () async {
      final id = const Uuid().v4();
      final backdated = DateTime(2020, 1, 1);
      await dataSource.addTransaction(
        buildEntry(id: id, occuredTime: Value(backdated)),
      );

      final result = (await dataSource.allTransactions).single;
      expect(result.occuredTime, backdated);
    });

    test('type round-trips as TransactionType enum, not a raw string', () async {
      final incomeId = const Uuid().v4();
      final expenseId = const Uuid().v4();
      await dataSource.addTransaction(
        buildEntry(id: incomeId, type: TransactionType.income),
      );
      await dataSource.addTransaction(
        buildEntry(id: expenseId, type: TransactionType.expense),
      );

      final result = await dataSource.allTransactions;
      final income = result.firstWhere((t) => t.id == incomeId);
      final expense = result.firstWhere((t) => t.id == expenseId);
      expect(income.type, TransactionType.income);
      expect(expense.type, TransactionType.expense);
    });

    test('duplicate id throws; distinct ids both succeed', () async {
      final id = const Uuid().v4();
      await dataSource.addTransaction(buildEntry(id: id));

      expect(
        () => dataSource.addTransaction(buildEntry(id: id)),
        throwsA(anything),
      );

      await dataSource.addTransaction(buildEntry(id: const Uuid().v4()));
      final result = await dataSource.allTransactions;
      expect(result.length, 2);
    });

    test('amountMinor stores exact integer values', () async {
      final id = const Uuid().v4();
      await dataSource.addTransaction(buildEntry(id: id, amountMinor: 350));

      final result = (await dataSource.allTransactions).single;
      expect(result.amountMinor, 350);
    });
  });

  group('deleteTransaction', () {
    test('deleting an existing id removes exactly that row', () async {
      final keepId = const Uuid().v4();
      final removeId = const Uuid().v4();
      await dataSource.addTransaction(buildEntry(id: keepId));
      await dataSource.addTransaction(buildEntry(id: removeId));

      await dataSource.deleteTransaction(removeId);

      final result = await dataSource.allTransactions;
      expect(result.length, 1);
      expect(result.single.id, keepId);
    });

    test('return value equals number of rows deleted (1)', () async {
      final id = const Uuid().v4();
      await dataSource.addTransaction(buildEntry(id: id));

      final deletedCount = await dataSource.deleteTransaction(id);
      expect(deletedCount, 1);
    });

    test('deleting a non-existent id returns 0, does not throw', () async {
      final deletedCount = await dataSource.deleteTransaction(const Uuid().v4());
      expect(deletedCount, 0);
    });
  });

  group('allTransactions', () {
    test('empty table returns []', () async {
      final result = await dataSource.allTransactions;
      expect(result, isEmpty);
    });

    test('multiple inserted rows are all present (order-independent)', () async {
      final ids = [const Uuid().v4(), const Uuid().v4(), const Uuid().v4()];
      for (final id in ids) {
        await dataSource.addTransaction(buildEntry(id: id));
      }

      final result = await dataSource.allTransactions;
      expect(result.map((t) => t.id).toSet(), ids.toSet());
    });

    test('reflects state after a mix of inserts and deletes', () async {
      final keepId = const Uuid().v4();
      final removeId = const Uuid().v4();
      await dataSource.addTransaction(buildEntry(id: keepId));
      await dataSource.addTransaction(buildEntry(id: removeId));

      await dataSource.deleteTransaction(removeId);

      final result = await dataSource.allTransactions;
      expect(result.length, 1);
      expect(result.single.id, keepId);
    });
  });


    

  });




}