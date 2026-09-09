import 'package:logger/logger.dart';
import 'package:stockflow/core/result.dart';
import 'package:stockflow/core/sync/data/datasources/supabase_sync_data_source.dart';
import 'package:stockflow/core/sync/domain/repositories/sync_queue_repository.dart';
import 'package:stockflow/core/sync/domain/repositories/sync_repository.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl({
    required this.syncQueueRepository,
    required this.supabaseSyncDataSource,
  });

  final SyncQueueRepository syncQueueRepository;
  final SupabaseSyncDataSource supabaseSyncDataSource;

  @override
  Future<Result<int>> pushPending() async {
    final pending = await syncQueueRepository.getPending();
    if (pending case Failure(:final message)) {
      return Failure(message);
    }

    final entries = (pending as Success).data;
    var succeeded = 0;

    for (final entry in entries) {
      try {
        await supabaseSyncDataSource.pushEntry(entry);
      } catch (e, st) {
        // Push failed (network, server rejection, etc.) -- leave this entry
        // queued and move on to the next one. No error/retry bookkeeping;
        // it'll simply be retried on the next pushPending() call. Logged
        // (not swallowed silently) so a persistent failure -- e.g. a schema
        // or RLS mismatch that will never succeed on retry -- is visible.
        // .toString() here, not .name -- a confirmed Dart tooling edge case
        // makes .name throw NoSuchMethodError specifically in this
        // catch-after-a-Result-pattern-match-and-loop shape (isolated and
        // reproduced independently of this file's actual types; .toString()
        // does not trigger it). Produces "OperationType.create" instead of
        // "create" in the log -- functionally identical, just the enum's
        // qualified name.
        _logger.w(
          'Sync push failed for ${entry.entityType}/${entry.id} '
          '(${entry.operation.toString()}): $e',
          error: e,
          stackTrace: st,
        );
        continue;
      }

      final dequeued = await syncQueueRepository.dequeue(entry.id);
      if (dequeued is Success) {
        succeeded++;
      }
      // If dequeue itself fails, the entry stays in the queue and the push
      // will just happen again next time -- harmless since pushEntry is
      // idempotent. Not counted as succeeded since it hasn't actually left
      // the queue yet.
    }

    return Success(succeeded);
  }
}
