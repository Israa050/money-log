import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stockflow/transactions/bloc/balance_cubit.dart';

import 'helpers/mocks.dart';

void main() {
  late MockTransactionsRepository mockTransactionsRepository;

  setUp(() {
    mockTransactionsRepository = MockTransactionsRepository();
  });

  group('BalanceCubit', () {
    test('initial state is 0 before the repository stream emits', () {
      when(
        () => mockTransactionsRepository.watchBalance(),
      ).thenAnswer((_) => const Stream.empty());

      final cubit = BalanceCubit(
        transactionsRepository: mockTransactionsRepository,
      );
      addTearDown(cubit.close);

      expect(cubit.state, 0);
    });

    blocTest<BalanceCubit, int>(
      'repository stream emits a value -> cubit emits that value',
      setUp: () {
        when(
          () => mockTransactionsRepository.watchBalance(),
        ).thenAnswer((_) => Stream.value(1500));
      },
      build: () =>
          BalanceCubit(transactionsRepository: mockTransactionsRepository),
      expect: () => [1500],
    );

    blocTest<BalanceCubit, int>(
      'repository stream emits multiple values -> cubit emits each in order',
      setUp: () {
        when(
          () => mockTransactionsRepository.watchBalance(),
        ).thenAnswer((_) => Stream.fromIterable([100, 250, 0, -50]));
      },
      build: () =>
          BalanceCubit(transactionsRepository: mockTransactionsRepository),
      expect: () => [100, 250, 0, -50],
    );
  });
}
