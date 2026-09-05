import 'dart:convert';

import 'package:stockflow/core/sync/domain/entities/operation_type.dart';
import 'package:stockflow/core/sync/domain/entities/sync_queue_entry_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSyncDataSource {
  final SupabaseClient client;

  SupabaseSyncDataSource({required this.client});

  static const _tableNames = {
    'transaction': 'transactions',
    'category': 'categories',
  };

  /// Pushes one queued change to Supabase. Throws on a real failure
  /// (network, RLS, bad table name) -- callers (SyncRepository.pushPending)
  /// catch per-entry so one failure doesn't block the rest of the queue.
  Future<void> pushEntry(SyncQueueEntryEntity entry) async {
    final tableName = _tableNames[entry.entityType] ?? entry.entityType;

    switch (entry.operation) {
      case OperationType.create:
      case OperationType.update:
        final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
        await client.from(tableName).upsert(payload);

      case OperationType.delete:
        // No rows-affected check needed: Postgrest's delete doesn't throw
        // when zero rows match, so deleting an already-gone row is already
        // a no-op success, not a Failure.
        await client.from(tableName).delete().eq('id', entry.entityId);
    }
  }
}
