import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stockflow/features/transactions/bloc/balance_cubit.dart';

import 'helpers/mocks.dart';

void main() {
  late MockWatchBalanceUseCase watchBalanceUseCase;

  setUp(() {
    watchBalanceUseCase = MockWatchBalanceUseCase();
  });

  group('BalanceCubit', () {
    test('initial state is 0 before the use case stream emits', () {
      when(() => watchBalanceUseCase()).thenAnswer((_) => const Stream.empty());

      final cubit = BalanceCubit(watchBalanceUseCase: watchBalanceUseCase);
      addTearDown(cubit.close);

      expect(cubit.state, 0);
    });

    blocTest<BalanceCubit, int>(
      'use case stream emits a value -> cubit emits that value',
      setUp: () {
        when(() => watchBalanceUseCase()).thenAnswer((_) => Stream.value(1500));
      },
      build: () => BalanceCubit(watchBalanceUseCase: watchBalanceUseCase),
      expect: () => [1500],
    );

    blocTest<BalanceCubit, int>(
      'use case stream emits multiple values -> cubit emits each in order',
      setUp: () {
        when(
          () => watchBalanceUseCase(),
        ).thenAnswer((_) => Stream.fromIterable([100, 250, 0, -50]));
      },
      build: () => BalanceCubit(watchBalanceUseCase: watchBalanceUseCase),
      expect: () => [100, 250, 0, -50],
    );
  });
}
