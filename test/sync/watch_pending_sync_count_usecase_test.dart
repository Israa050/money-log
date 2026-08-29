import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stockflow/core/sync/domain/usecases/watch_pending_sync_count_usecase.dart';

import '../helpers/mocks.dart';

void main() {
  late MockSyncQueueRepository repository;
  late WatchPendingSyncCountUseCase useCase;

  setUp(() {
    repository = MockSyncQueueRepository();
    useCase = WatchPendingSyncCountUseCase(repository);
  });

  test('call() returns the repository stream unchanged (same instance)', () {
    final stream = Stream.fromIterable([0, 1, 2]);
    when(() => repository.watchPendingCount()).thenAnswer((_) => stream);

    expect(useCase(), same(stream));
    verify(() => repository.watchPendingCount()).called(1);
  });

  test('call() emits exactly what the repository stream emits, in order', () {
    when(
      () => repository.watchPendingCount(),
    ).thenAnswer((_) => Stream.fromIterable([0, 1, 2]));

    expect(useCase(), emitsInOrder([0, 1, 2]));
  });
}
