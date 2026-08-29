import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stockflow/core/connectivity/domain/network_status.dart';
import 'package:stockflow/core/connectivity/domain/usecases/watch_connectivity_usecase.dart';

import '../helpers/mocks.dart';

void main() {
  late MockConnectivityRepository repository;
  late WatchConnectivityUseCase useCase;

  setUp(() {
    repository = MockConnectivityRepository();
    useCase = WatchConnectivityUseCase(repository);
  });

  test('call() returns the repository stream unchanged (same instance)', () {
    final stream = Stream.fromIterable([
      NetworkStatus.offline,
      NetworkStatus.online,
    ]);
    when(() => repository.watchConnectivityChanges()).thenAnswer((_) => stream);

    expect(useCase(), same(stream));
    verify(() => repository.watchConnectivityChanges()).called(1);
  });

  test('call() emits exactly what the repository stream emits, in order', () {
    when(() => repository.watchConnectivityChanges()).thenAnswer(
      (_) => Stream.fromIterable([NetworkStatus.offline, NetworkStatus.online]),
    );

    expect(
      useCase(),
      emitsInOrder([NetworkStatus.offline, NetworkStatus.online]),
    );
  });
}
