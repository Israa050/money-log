import 'dart:convert';

import 'package:flutter/foundation.dart';
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
        final local = jsonDecode(entry.payload) as Map<String, dynamic>;
        final userId = client.auth.currentUser!.id;
        final payload = mapForSupabase(entry.entityType, local, userId);
        await client.from(tableName).upsert(payload);

      case OperationType.delete:
        // No rows-affected check needed: Postgrest's delete doesn't throw
        // when zero rows match, so deleting an already-gone row is already
        // a no-op success, not a Failure.
        await client.from(tableName).delete().eq('id', entry.entityId);
    }
  }

  /// Translates a locally-stored payload (camelCase, Drift-native field
  /// names) into the shape Supabase's tables actually expect (snake_case,
  /// plus the owning user_id required by their "own rows only" RLS
  /// policies). Kept separate from the local payload format so queued rows
  /// from before a remote schema change still push correctly after an app
  /// update changes this mapping.
  ///
  /// Exposed via `@visibleForTesting` -- calling this directly is the only
  /// practical way to test this mapping, since mocking the Supabase SDK's
  /// `client.from(...).upsert(...)` chain hits a fundamental limitation:
  /// its awaitability comes from an overridden generic `then` method,
  /// which mocktail cannot reliably intercept (confirmed by two separate
  /// mock attempts, both failing with a "type 'Null' is not a subtype of
  /// type `Future<dynamic>`" error even with the correct named-parameter
  /// matcher). Testing the mapping directly avoids depending on SDK
  /// internals mocktail can't safely fake.
  @visibleForTesting
  Map<String, dynamic> mapForSupabase(
    String entityType,
    Map<String, dynamic> local,
    String userId,
  ) {
    switch (entityType) {
      case 'transaction':
        return {
          'id': local['id'],
          'user_id': userId,
          'amount_minor': local['amountMinor'],
          'type': local['type'],
          'note': local['note'],
          'category_id': local['categoryId'],
          'occurred_at': local['occurredTime'],
          'created_at': local['creationTime'],
        };
      case 'category':
        return {
          'id': local['id'],
          'user_id': userId,
          'name': local['name'],
          'color_hex': local['colorHex'],
        };
      default:
        return local;
    }
  }
}
