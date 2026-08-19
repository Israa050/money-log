import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stockflow/core/result.dart';
import 'package:stockflow/transactions/bloc/transactions_bloc.dart';
import 'package:stockflow/transactions/domain/entities/transaction_entity.dart';
import 'package:stockflow/transactions/domain/entities/transaction_type.dart';

import 'helpers/mocks.dart';

void main() {
  late MockGetTransactionsUseCase getTransactionsUseCase;
  late MockAddTransactionUseCase addTransactionUseCase;
  late MockDeleteTransactionUseCase deleteTransactionUseCase;
  late MockWatchCategoriesUseCase watchCategoriesUseCase;
  late TransactionsBloc transactionsBloc;

  final fakeTransactions = [
    TransactionEntity(
      id: 't1',
      amountMinor: 500,
      type: TransactionType.expense,
      note: 'coffee',
      timestamp: DateTime(2024, 1, 1),
      categoryId: 'default-food',
    ),
    TransactionEntity(
      id: 't2',
      amountMinor: 1000,
      type: TransactionType.income,
      note: null,
      timestamp: DateTime(2024, 1, 2),
      categoryId: null,
    ),
  ];

  setUp(() {
    getTransactionsUseCase = MockGetTransactionsUseCase();
    addTransactionUseCase = MockAddTransactionUseCase();
    deleteTransactionUseCase = MockDeleteTransactionUseCase();
    watchCategoriesUseCase = MockWatchCategoriesUseCase();
    when(() => watchCategoriesUseCase()).thenAnswer((_) => Stream.empty());
    transactionsBloc = TransactionsBloc(
      getTransactionsUseCase: getTransactionsUseCase,
      addTransactionUseCase: addTransactionUseCase,
      deleteTransactionUseCase: deleteTransactionUseCase,
      watchCategoriesUseCase: watchCategoriesUseCase,
    );
    registerFallbackValue(TransactionType.expense);
  });

  tearDown(() {
    transactionsBloc.close();
  });

  group('AppLaunchEvent success', () {
    test(
      'initial state is TransactionsInitial before any event',
      () => expect(transactionsBloc.state, isA<TransactionsInitial>()),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'use case stream emits data -> emits Loaded with that data',
      setUp: () {
        when(
          () => getTransactionsUseCase(),
        ).thenAnswer((_) => Stream.value(fakeTransactions));
      },
      build: () => transactionsBloc,
      act: (bloc) => bloc.add(AppLaunchEvent()),
      expect: () => [
        isA<Loaded>().having((s) => s.data, 'data', fakeTransactions),
      ],
    );
  });

  group('AppLaunchEvent failure', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'use case stream emits an error -> emits TransactionsError',
      setUp: () {
        when(
          () => getTransactionsUseCase(),
        ).thenAnswer((_) => Stream.error('Data not found'));
      },
      build: () => transactionsBloc,
      act: (bloc) => bloc.add(AppLaunchEvent()),
      expect: () => [
        isA<TransactionsError>()
            .having((s) => s.message, 'message', 'Data not found')
            .having((s) => s.previousData, 'previousData', isEmpty),
      ],
    );
  });

  group('AddTransactionEvent success', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'use case add succeeds -> emits nothing directly',
      setUp: () {
        when(
          () => addTransactionUseCase(
            amountMinor: any(named: 'amountMinor'),
            type: any(named: 'type'),
            note: any(named: 'note'),
          ),
        ).thenAnswer((_) async => const Success(null));
      },
      build: () => transactionsBloc,
      act: (bloc) => bloc.add(
        AddTransactionEvent(
          amountMinor: 500,
          type: TransactionType.expense,
          note: 'Coffee',
        ),
      ),
      expect: () => [],
      verify: (_) => verify(
        () => addTransactionUseCase(
          amountMinor: 500,
          type: TransactionType.expense,
          note: 'Coffee',
        ),
      ).called(1),
    );
  });

  group('AddTransactionEvent failure', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'use case add fails with no prior data -> emits TransactionsError with empty previousData',
      setUp: () {
        when(
          () => addTransactionUseCase(
            amountMinor: any(named: 'amountMinor'),
            type: any(named: 'type'),
            note: any(named: 'note'),
          ),
        ).thenAnswer((_) async => const Failure('Failed To Load'));
      },
      build: () => transactionsBloc,
      act: (bloc) => bloc.add(
        AddTransactionEvent(
          amountMinor: 500,
          type: TransactionType.expense,
          note: 'Coffee',
        ),
      ),
      expect: () => [
        isA<TransactionsError>()
            .having((s) => s.message, 'message', 'Failed To Load')
            .having((s) => s.previousData, 'previousData', isEmpty),
      ],
      verify: (_) => verify(
        () => addTransactionUseCase(
          amountMinor: 500,
          type: TransactionType.expense,
          note: 'Coffee',
        ),
      ).called(1),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'use case add fails after data was loaded -> emits TransactionsError with previousData preserved',
      setUp: () {
        when(
          () => addTransactionUseCase(
            amountMinor: any(named: 'amountMinor'),
            type: any(named: 'type'),
            note: any(named: 'note'),
          ),
        ).thenAnswer((_) async => const Failure('Failed To Load'));
      },
      build: () => transactionsBloc,
      seed: () => Loaded(data: fakeTransactions, categories: const []),
      act: (bloc) => bloc.add(
        AddTransactionEvent(
          amountMinor: 500,
          type: TransactionType.expense,
          note: 'Coffee',
        ),
      ),
      expect: () => [
        isA<TransactionsError>()
            .having((s) => s.message, 'message', 'Failed To Load')
            .having((s) => s.previousData, 'previousData', fakeTransactions),
      ],
      verify: (_) => verify(
        () => addTransactionUseCase(
          amountMinor: 500,
          type: TransactionType.expense,
          note: 'Coffee',
        ),
      ).called(1),
    );
  });

  group('DeleteTransactionEvent success', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'use case delete succeeds -> emits nothing directly',
      setUp: () {
        when(
          () => deleteTransactionUseCase(any()),
        ).thenAnswer((_) async => const Success(1));
      },
      build: () => transactionsBloc,
      act: (bloc) => bloc.add(DeleteTransactionEvent(id: '1234')),
      expect: () => [],
      verify: (_) => verify(() => deleteTransactionUseCase('1234')).called(1),
    );
  });

  group('DeleteTransactionEvent failure', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'use case delete fails with no prior data -> emits TransactionsError with empty previousData',
      setUp: () {
        when(
          () => deleteTransactionUseCase(any()),
        ).thenAnswer((_) async => const Failure('Data cannot be deleted'));
      },
      build: () => transactionsBloc,
      act: (bloc) => bloc.add(DeleteTransactionEvent(id: '1234')),
      expect: () => [
        isA<TransactionsError>()
            .having((s) => s.message, 'message', 'Data cannot be deleted')
            .having((s) => s.previousData, 'previousData', isEmpty),
      ],
      verify: (_) => verify(() => deleteTransactionUseCase('1234')).called(1),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'use case delete fails after data was loaded -> emits TransactionsError with previousData preserved',
      setUp: () {
        when(
          () => deleteTransactionUseCase(any()),
        ).thenAnswer((_) async => const Failure('Data cannot be deleted'));
      },
      build: () => transactionsBloc,
      seed: () => Loaded(data: fakeTransactions, categories: const []),
      act: (bloc) => bloc.add(DeleteTransactionEvent(id: '1234')),
      expect: () => [
        isA<TransactionsError>()
            .having((s) => s.message, 'message', 'Data cannot be deleted')
            .having((s) => s.previousData, 'previousData', fakeTransactions),
      ],
      verify: (_) => verify(() => deleteTransactionUseCase('1234')).called(1),
    );
  });
}
