import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stockflow/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:stockflow/core/connectivity/domain/network_status.dart';

import '../helpers/mocks.dart';

void main() {
  late MockWatchConnectivityUseCase connectivityUseCase;

  setUp(() {
    connectivityUseCase = MockWatchConnectivityUseCase();
  });

  group('ConnectivityCubit', () {
    test('initial state is online before the use case stream emits', () {
      when(() => connectivityUseCase()).thenAnswer((_) => Stream.empty());

      final cubit = ConnectivityCubit(
        watchConnectivityUseCase: connectivityUseCase,
      );

      addTearDown(cubit.close);

      expect(cubit.state, NetworkStatus.online);
    });

    blocTest<ConnectivityCubit, NetworkStatus>(
      'use case stream emits offline -> cubit emits offline',
      setUp: () {
        when(
          () => connectivityUseCase(),
        ).thenAnswer((_) => Stream.value(NetworkStatus.offline));
      },
      build: () =>
          ConnectivityCubit(watchConnectivityUseCase: connectivityUseCase),
      expect: () => [NetworkStatus.offline],
    );

    blocTest<ConnectivityCubit, NetworkStatus>(
      'use case stream emits multiple values -> cubit emits each in order',
      setUp: () {
        when(() => connectivityUseCase()).thenAnswer(
          (_) => Stream.fromIterable([
            NetworkStatus.offline,
            NetworkStatus.online,
            NetworkStatus.offline,
          ]),
        );
      },
      build: () =>
          ConnectivityCubit(watchConnectivityUseCase: connectivityUseCase),
      expect: () => [
        NetworkStatus.offline,
        NetworkStatus.online,
        NetworkStatus.offline,
      ],
    );

    blocTest<ConnectivityCubit, NetworkStatus>(
      'consecutive duplicate values from the stream are collapsed',
      setUp: () {
        when(() => connectivityUseCase()).thenAnswer(
          (_) => Stream.fromIterable([
            NetworkStatus.offline,
            NetworkStatus.offline,
            NetworkStatus.online,
          ]),
        );
      },
      build: () =>
          ConnectivityCubit(watchConnectivityUseCase: connectivityUseCase),
      expect: () => [NetworkStatus.offline, NetworkStatus.online],
    );

    test('close() cancels the subscription -- no emit after close', () async {
      final controller = StreamController<NetworkStatus>();
      addTearDown(controller.close);
      when(() => connectivityUseCase()).thenAnswer((_) => controller.stream);

      final cubit = ConnectivityCubit(
        watchConnectivityUseCase: connectivityUseCase,
      );

      final emitted = <NetworkStatus>[];
      final sub = cubit.stream.listen(emitted.add);
      addTearDown(sub.cancel);

      await cubit.close();

      controller.add(NetworkStatus.offline);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
    });
  });
}
