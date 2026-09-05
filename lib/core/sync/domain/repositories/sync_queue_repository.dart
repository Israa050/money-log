import 'package:stockflow/core/result.dart';
import 'package:stockflow/core/sync/domain/entities/operation_type.dart';
import 'package:stockflow/core/sync/domain/entities/sync_queue_entry_entity.dart';

abstract class SyncQueueRepository {
  /// Records that [entityType]/[entityId] changed via [operation], so a
  /// later sync process can push [payload] to the server. Always called,
  /// online or offline (Option A) -- id and createdAt are generated
  /// internally, not supplied by the caller.
  Future<Result<int>> enqueue({
    required String entityType,
    required String entityId,
    required OperationType operation,
    required String payload,
  });

  /// Total rows currently in the queue. There is no synced/status column
  /// yet, so every row counts as pending -- this will need to filter to
  /// unsynced rows once a drain process can mark or remove them.
  Stream<int> watchPendingCount();

  /// All rows currently queued, oldest and newest alike -- there is no
  /// status column, so every row returned here is "not yet pushed".
  Future<Result<List<SyncQueueEntryEntity>>> getPending();

  /// Removes [id] from the queue after it has been successfully pushed.
  Future<Result<void>> dequeue(String id);
}
