import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stockflow/core/connectivity/data/connectivity_repository_impl.dart';
import 'package:stockflow/core/connectivity/domain/network_status.dart';
import 'package:stockflow/core/result.dart';

import '../helpers/mocks.dart';

void main() {
  late MockConnectivity connectivity;
  late ConnectivityRepositoryImpl repository;

  setUp(() {
    connectivity = MockConnectivity();
    repository = ConnectivityRepositoryImpl(connectivity: connectivity);
  });

  NetworkStatus statusOf(Result<NetworkStatus> result) =>
      (result as Success<NetworkStatus>).data;

  group('checkConnectivity', () {
    test('a single active interface -> Success(online)', () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      final result = await repository.checkConnectivity();

      expect(result, isA<Success<NetworkStatus>>());
      expect(statusOf(result), NetworkStatus.online);
    });

    test('[none] -> Success(offline)', () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      expect(
        statusOf(await repository.checkConnectivity()),
        NetworkStatus.offline,
      );
    });

    test('an empty result list -> Success(offline)', () async {
      when(() => connectivity.checkConnectivity()).thenAnswer((_) async => []);

      expect(
        statusOf(await repository.checkConnectivity()),
        NetworkStatus.offline,
      );
    });

    test('one active interface among several none values -> Success(online) '
        '(the rule is "every result is none", not "contains none")', () async {
      when(() => connectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.none, ConnectivityResult.mobile],
      );

      expect(
        statusOf(await repository.checkConnectivity()),
        NetworkStatus.online,
      );
    });

    test('every result is none -> Success(offline)', () async {
      when(() => connectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.none, ConnectivityResult.none],
      );

      expect(
        statusOf(await repository.checkConnectivity()),
        NetworkStatus.offline,
      );
    });

    test('the plugin throws -> Failure carrying the error message', () async {
      when(() => connectivity.checkConnectivity()).thenThrow(Exception('boom'));

      final result = await repository.checkConnectivity();

      expect(result, isA<Failure<NetworkStatus>>());
      expect((result as Failure<NetworkStatus>).message, contains('boom'));
    });
  });

  group('watchConnectivityChanges', () {
    test('maps each emission through the same rule, in order', () {
      when(() => connectivity.onConnectivityChanged).thenAnswer(
        (_) => Stream.fromIterable([
          [ConnectivityResult.wifi],
          [ConnectivityResult.none],
          [ConnectivityResult.none, ConnectivityResult.mobile],
          <ConnectivityResult>[],
        ]),
      );

      expect(
        repository.watchConnectivityChanges(),
        emitsInOrder([
          NetworkStatus.online,
          NetworkStatus.offline,
          NetworkStatus.online,
          NetworkStatus.offline,
        ]),
      );
    });

    test('an empty source stream -> completes with no emissions', () {
      when(
        () => connectivity.onConnectivityChanged,
      ).thenAnswer((_) => const Stream.empty());

      expect(repository.watchConnectivityChanges(), emitsDone);
    });
  });
}
