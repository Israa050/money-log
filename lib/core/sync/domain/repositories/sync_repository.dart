import 'package:stockflow/core/result.dart';

abstract class SyncRepository {
  /// Pushes every queued change to the server, one entry at a time.
  ///
  /// Each entry is pushed and dequeued independently -- one entry failing
  /// (network error, server rejection, etc.) does not stop the rest from
  /// being attempted, and the failed entry is simply left in the queue for
  /// the next call to retry. There is no status/retry-count/error column:
  /// presence in the queue is the only state that's tracked, which is safe
  /// because pushing an entry is idempotent (upsert, or a delete that's a
  /// no-op if the row is already gone).
  ///
  /// Returns the number of entries that were successfully pushed *and*
  /// removed from the queue.
  Future<Result<int>> pushPending();

  /// Pulls rows changed remotely since each entity type's own last pull and
  /// applies them locally with last-write-wins (newer `updated_at` wins).
  /// Transactions and categories are pulled/watermarked independently.
  /// Remote deletes are not propagated (no tombstone on push).
  ///
  /// Returns the number of rows applied locally, across both entity types.
  Future<Result<int>> pullRemoteChanges();
}
