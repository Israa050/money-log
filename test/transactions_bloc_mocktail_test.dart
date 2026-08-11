import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stockflow/core/result.dart';
import 'package:stockflow/transactions/bloc/transactions_bloc.dart';
import 'package:stockflow/transactions/data/models/transactions.dart';
import 'package:stockflow/transactions/data/transactions_data_source.dart';

import 'helpers/mocks.dart';

void main() {
  late MockTransactionsRepository mockTransactionsRepository;
  late TransactionsBloc transactionsBloc;

  final fakeTransactions = [
    Transaction(
      id: 't1',
      amountMinor: 500,
      type: TransactionType.expense,
      note: 'coffee',
      occuredTime: DateTime(2024, 1, 1),
      creationTime: DateTime(2024, 1, 1),
    ),
    Transaction(
      id: 't2',
      amountMinor: 1000,
      type: TransactionType.income,
      note: null,
      occuredTime: DateTime(2024, 1, 2),
      creationTime: DateTime(2024, 1, 2),
    ),
  ];

  setUp(() {
    mockTransactionsRepository = MockTransactionsRepository();
    transactionsBloc = TransactionsBloc(
      transactionsRepository: mockTransactionsRepository,
    );
    registerFallbackValue(FakeTransactionsCompanion());
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
      'repository stream emits data -> emits Loaded with that data',
      setUp: () {
        when(
          () => mockTransactionsRepository.getAllTransactions(),
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
      'repository stream emits an error -> emits TransactionsError',
      setUp: () {
        when(
          () => mockTransactionsRepository.getAllTransactions(),
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
      'repository add succeeds -> emits nothing directly',
      setUp: () {
        when(
          () => mockTransactionsRepository.newTransactionEntry(
            amountMinor: any(named: 'amountMinor'),
            type: any(named: 'type'),
            note: any(named: 'note'),
          ),
        ).thenReturn(FakeTransactionsCompanion());
        when(
          () => mockTransactionsRepository.addTransaction(any()),
        ).thenAnswer((_) async => Success(1));
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
        () => mockTransactionsRepository.addTransaction(any()),
      ).called(1),
    );
  });

  group('AddTransactionEvent failure', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'repository add fails with no prior data -> emits TransactionsError with empty previousData',
      setUp: () {
        when(
          () => mockTransactionsRepository.newTransactionEntry(
            amountMinor: any(named: 'amountMinor'),
            type: any(named: 'type'),
            note: any(named: 'note'),
          ),
        ).thenReturn(FakeTransactionsCompanion());
        when(
          () => mockTransactionsRepository.addTransaction(any()),
        ).thenAnswer((_) async => Failure('Failed To Load'));
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
        () => mockTransactionsRepository.addTransaction(any()),
      ).called(1),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'repository add fails after data was loaded -> emits TransactionsError with previousData preserved',
      setUp: () {
        when(
          () => mockTransactionsRepository.newTransactionEntry(
            amountMinor: any(named: 'amountMinor'),
            type: any(named: 'type'),
            note: any(named: 'note'),
          ),
        ).thenReturn(FakeTransactionsCompanion());
        when(
          () => mockTransactionsRepository.addTransaction(any()),
        ).thenAnswer((_) async => Failure('Failed To Load'));
      },
      build: () => transactionsBloc,
      seed: () => Loaded(data: fakeTransactions),
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
        () => mockTransactionsRepository.addTransaction(any()),
      ).called(1),
    );
  });

  group('DeleteTransactionEvent success', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'repository delete succeeds -> emits nothing directly',
      setUp: () {
        when(
          () => mockTransactionsRepository.deleteTransaction(any()),
        ).thenAnswer((_) async => Success(1));
      },
      build: () => transactionsBloc,
      act: (bloc) => bloc.add(DeleteTransactionEvent(id: '1234')),
      expect: () => [],
      verify: (_) => verify(
        () => mockTransactionsRepository.deleteTransaction(any()),
      ).called(1),
    );
  });

  group('DeleteTransactionEvent failure', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'repository delete fails with no prior data -> emits TransactionsError with empty previousData',
      setUp: () {
        when(
          () => mockTransactionsRepository.deleteTransaction(any()),
        ).thenAnswer((_) async => Failure('Data cannot be deleted'));
      },
      build: () => transactionsBloc,
      act: (bloc) => bloc.add(DeleteTransactionEvent(id: '1234')),
      expect: () => [
        isA<TransactionsError>()
            .having((s) => s.message, 'message', 'Data cannot be deleted')
            .having((s) => s.previousData, 'previousData', isEmpty),
      ],
      verify: (_) => verify(
        () => mockTransactionsRepository.deleteTransaction(any()),
      ).called(1),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'repository delete fails after data was loaded -> emits TransactionsError with previousData preserved',
      setUp: () {
        when(
          () => mockTransactionsRepository.deleteTransaction(any()),
        ).thenAnswer((_) async => Failure('Data cannot be deleted'));
      },
      build: () => transactionsBloc,
      seed: () => Loaded(data: fakeTransactions),
      act: (bloc) => bloc.add(DeleteTransactionEvent(id: '1234')),
      expect: () => [
        isA<TransactionsError>()
            .having((s) => s.message, 'message', 'Data cannot be deleted')
            .having((s) => s.previousData, 'previousData', fakeTransactions),
      ],
      verify: (_) => verify(
        () => mockTransactionsRepository.deleteTransaction(any()),
      ).called(1),
    );
  });
}
