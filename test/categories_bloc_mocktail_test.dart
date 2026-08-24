import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stockflow/core/result.dart';
import 'package:stockflow/features/categories/bloc/categories_bloc.dart';
import 'package:stockflow/features/categories/domain/entities/category_entity.dart';

import 'helpers/mocks.dart';

void main() {
  late MockWatchCategoriesUseCase watchCategoriesUseCase;
  late MockAddCategoryUseCase addCategoryUseCase;
  late MockUpdateCategoryUseCase updateCategoryUseCase;
  late MockDeleteCategoryUseCase deleteCategoryUseCase;
  late CategoriesBloc categoriesBloc;

  final fakeCategories = [
    CategoryEntity(id: 'c1', name: 'Food', colorHex: '#FF9800'),
    CategoryEntity(id: 'c2', name: 'Transport', colorHex: null),
  ];

  setUp(() {
    watchCategoriesUseCase = MockWatchCategoriesUseCase();
    addCategoryUseCase = MockAddCategoryUseCase();
    updateCategoryUseCase = MockUpdateCategoryUseCase();
    deleteCategoryUseCase = MockDeleteCategoryUseCase();
    categoriesBloc = CategoriesBloc(
      watchCategoriesUseCase: watchCategoriesUseCase,
      addCategoryUseCase: addCategoryUseCase,
      updateCategoryUseCase: updateCategoryUseCase,
      deleteCategoryUseCase: deleteCategoryUseCase,
    );
  });

  tearDown(() {
    categoriesBloc.close();
  });

  group('CategoriesStarted success', () {
    test(
      'initial state is CategoriesInitial before any event',
      () => expect(categoriesBloc.state, isA<CategoriesInitial>()),
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'use case stream emits data -> emits CategoriesLoaded with that data',
      setUp: () {
        when(
          () => watchCategoriesUseCase(),
        ).thenAnswer((_) => Stream.value(fakeCategories));
      },
      build: () => categoriesBloc,
      act: (bloc) => bloc.add(CategoriesStarted()),
      expect: () => [
        isA<CategoriesLoaded>().having((s) => s.data, 'data', fakeCategories),
      ],
    );
  });

  group('CategoriesStarted failure', () {
    blocTest<CategoriesBloc, CategoriesState>(
      'use case stream emits an error -> emits CategoriesError',
      setUp: () {
        when(
          () => watchCategoriesUseCase(),
        ).thenAnswer((_) => Stream.error('Data not found'));
      },
      build: () => categoriesBloc,
      act: (bloc) => bloc.add(CategoriesStarted()),
      expect: () => [
        isA<CategoriesError>()
            .having((s) => s.message, 'message', 'Data not found')
            .having((s) => s.previousData, 'previousData', isEmpty),
      ],
    );
  });

  group('AddCategoryEvent success', () {
    blocTest<CategoriesBloc, CategoriesState>(
      'use case add succeeds -> emits nothing directly',
      setUp: () {
        when(
          () => addCategoryUseCase(
            name: any(named: 'name'),
            colorHex: any(named: 'colorHex'),
          ),
        ).thenAnswer((_) async => const Success(null));
      },
      build: () => categoriesBloc,
      act: (bloc) =>
          bloc.add(AddCategoryEvent(name: 'Groceries', colorHex: '#123456')),
      expect: () => [],
      verify: (_) => verify(
        () => addCategoryUseCase(name: 'Groceries', colorHex: '#123456'),
      ).called(1),
    );
  });

  group('AddCategoryEvent failure', () {
    blocTest<CategoriesBloc, CategoriesState>(
      'use case add fails with no prior data -> emits CategoriesError with empty previousData',
      setUp: () {
        when(
          () => addCategoryUseCase(
            name: any(named: 'name'),
            colorHex: any(named: 'colorHex'),
          ),
        ).thenAnswer((_) async => const Failure('Name already exists'));
      },
      build: () => categoriesBloc,
      act: (bloc) => bloc.add(AddCategoryEvent(name: 'Groceries')),
      expect: () => [
        isA<CategoriesError>()
            .having((s) => s.message, 'message', 'Name already exists')
            .having((s) => s.previousData, 'previousData', isEmpty),
      ],
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'use case add fails after data was loaded -> emits CategoriesError with previousData preserved',
      setUp: () {
        when(
          () => addCategoryUseCase(
            name: any(named: 'name'),
            colorHex: any(named: 'colorHex'),
          ),
        ).thenAnswer((_) async => const Failure('Name already exists'));
      },
      build: () => categoriesBloc,
      seed: () => CategoriesLoaded(data: fakeCategories),
      act: (bloc) => bloc.add(AddCategoryEvent(name: 'Groceries')),
      expect: () => [
        isA<CategoriesError>()
            .having((s) => s.message, 'message', 'Name already exists')
            .having((s) => s.previousData, 'previousData', fakeCategories),
      ],
    );
  });

  group('UpdateCategoryEvent success', () {
    blocTest<CategoriesBloc, CategoriesState>(
      'use case update succeeds -> emits nothing directly',
      setUp: () {
        when(
          () => updateCategoryUseCase(
            id: any(named: 'id'),
            name: any(named: 'name'),
            colorHex: any(named: 'colorHex'),
          ),
        ).thenAnswer((_) async => const Success(null));
      },
      build: () => categoriesBloc,
      act: (bloc) => bloc.add(UpdateCategoryEvent(id: 'c1', name: 'Snacks')),
      expect: () => [],
      verify: (_) => verify(
        () => updateCategoryUseCase(id: 'c1', name: 'Snacks', colorHex: null),
      ).called(1),
    );
  });

  group('UpdateCategoryEvent failure', () {
    blocTest<CategoriesBloc, CategoriesState>(
      'use case update fails after data was loaded -> emits CategoriesError with previousData preserved',
      setUp: () {
        when(
          () => updateCategoryUseCase(
            id: any(named: 'id'),
            name: any(named: 'name'),
            colorHex: any(named: 'colorHex'),
          ),
        ).thenAnswer((_) async => const Failure('Name already exists'));
      },
      build: () => categoriesBloc,
      seed: () => CategoriesLoaded(data: fakeCategories),
      act: (bloc) => bloc.add(UpdateCategoryEvent(id: 'c1', name: 'Food')),
      expect: () => [
        isA<CategoriesError>()
            .having((s) => s.message, 'message', 'Name already exists')
            .having((s) => s.previousData, 'previousData', fakeCategories),
      ],
    );
  });

  group('DeleteCategoryEvent success', () {
    blocTest<CategoriesBloc, CategoriesState>(
      'use case delete succeeds -> emits nothing directly',
      setUp: () {
        when(
          () => deleteCategoryUseCase(any()),
        ).thenAnswer((_) async => const Success(1));
      },
      build: () => categoriesBloc,
      act: (bloc) => bloc.add(DeleteCategoryEvent(id: 'c1')),
      expect: () => [],
      verify: (_) => verify(() => deleteCategoryUseCase('c1')).called(1),
    );
  });

  group('DeleteCategoryEvent failure', () {
    blocTest<CategoriesBloc, CategoriesState>(
      'use case delete fails with no prior data -> emits CategoriesError with empty previousData',
      setUp: () {
        when(
          () => deleteCategoryUseCase(any()),
        ).thenAnswer((_) async => const Failure('Category cannot be deleted'));
      },
      build: () => categoriesBloc,
      act: (bloc) => bloc.add(DeleteCategoryEvent(id: 'c1')),
      expect: () => [
        isA<CategoriesError>()
            .having((s) => s.message, 'message', 'Category cannot be deleted')
            .having((s) => s.previousData, 'previousData', isEmpty),
      ],
      verify: (_) => verify(() => deleteCategoryUseCase('c1')).called(1),
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'use case delete fails after data was loaded -> emits CategoriesError with previousData preserved',
      setUp: () {
        when(
          () => deleteCategoryUseCase(any()),
        ).thenAnswer((_) async => const Failure('Category cannot be deleted'));
      },
      build: () => categoriesBloc,
      seed: () => CategoriesLoaded(data: fakeCategories),
      act: (bloc) => bloc.add(DeleteCategoryEvent(id: 'c1')),
      expect: () => [
        isA<CategoriesError>()
            .having((s) => s.message, 'message', 'Category cannot be deleted')
            .having((s) => s.previousData, 'previousData', fakeCategories),
      ],
      verify: (_) => verify(() => deleteCategoryUseCase('c1')).called(1),
    );
  });
}
