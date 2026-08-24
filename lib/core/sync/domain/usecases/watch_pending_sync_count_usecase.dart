import 'package:stockflow/core/sync/domain/repositories/sync_queue_repository.dart';

class WatchPendingSyncCountUseCase {
  WatchPendingSyncCountUseCase(this._repository);

  final SyncQueueRepository _repository;

  Stream<int> call() {
    return _repository.watchPendingCount();
  }
}
