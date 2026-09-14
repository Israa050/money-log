import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stockflow/core/sync/data/datasources/supabase_sync_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late SupabaseSyncDataSource dataSource;

  setUp(() {
    // pushEntry() itself is not under test here (see mapForSupabase's doc
    // comment for why) -- the client is only needed to construct
    // SupabaseSyncDataSource, so it's never stubbed or touched.
    dataSource = SupabaseSyncDataSource(client: MockSupabaseClient());
  });

  group('mapForSupabase - transaction', () {
    test(
      'maps every camelCase local field to its snake_case remote column',
      () {
        final result = dataSource.mapForSupabase('transaction', {
          'id': 'txn-1',
          'amountMinor': 500,
          'type': 'expense',
          'note': 'coffee',
          'categoryId': 'cat-1',
          'occurredTime': '2026-01-01T00:00:00.000Z',
          'creationTime': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
        }, 'user-123');

        expect(result, {
          'id': 'txn-1',
          'user_id': 'user-123',
          'amount_minor': 500,
          'type': 'expense',
          'note': 'coffee',
          'category_id': 'cat-1',
          'occurred_at': '2026-01-01T00:00:00.000Z',
          'created_at': '2026-01-01T00:00:00.000Z',
          'updated_at': '2026-01-01T00:00:00.000Z',
        });
      },
    );

    test('stamps the given userId as user_id, not anything from local', () {
      final result = dataSource.mapForSupabase('transaction', {
        'id': 'txn-1',
        'amountMinor': 500,
        'type': 'expense',
        'note': null,
        'categoryId': null,
        'occurredTime': '2026-01-01T00:00:00.000Z',
        'creationTime': '2026-01-01T00:00:00.000Z',
      }, 'the-signed-in-user');

      expect(result['user_id'], 'the-signed-in-user');
    });

    test(
      'null note/categoryId pass through as null, not dropped or defaulted',
      () {
        final result = dataSource.mapForSupabase('transaction', {
          'id': 'txn-1',
          'amountMinor': 500,
          'type': 'expense',
          'note': null,
          'categoryId': null,
          'occurredTime': '2026-01-01T00:00:00.000Z',
          'creationTime': '2026-01-01T00:00:00.000Z',
        }, 'user-123');

        expect(result.containsKey('note'), true);
        expect(result['note'], null);
        expect(result.containsKey('category_id'), true);
        expect(result['category_id'], null);
      },
    );

    test('the old camelCase keys never appear in the output', () {
      final result = dataSource.mapForSupabase('transaction', {
        'id': 'txn-1',
        'amountMinor': 500,
        'type': 'expense',
        'note': 'coffee',
        'categoryId': 'cat-1',
        'occurredTime': '2026-01-01T00:00:00.000Z',
        'creationTime': '2026-01-01T00:00:00.000Z',
      }, 'user-123');

      for (final camelKey in [
        'amountMinor',
        'categoryId',
        'occurredTime',
        'creationTime',
      ]) {
        expect(
          result.containsKey(camelKey),
          false,
          reason: '$camelKey should have been renamed, not carried over',
        );
      }
    });
  });

  group('mapForSupabase - category', () {
    test('maps id/name/colorHex to id/name/color_hex plus user_id', () {
      final result = dataSource.mapForSupabase('category', {
        'id': 'cat-1',
        'name': 'Food',
        'colorHex': '#FF9800',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      }, 'user-123');

      expect(result, {
        'id': 'cat-1',
        'user_id': 'user-123',
        'name': 'Food',
        'color_hex': '#FF9800',
        'updated_at': '2026-01-01T00:00:00.000Z',
      });
    });

    test('null colorHex passes through as null', () {
      final result = dataSource.mapForSupabase('category', {
        'id': 'cat-1',
        'name': 'Food',
        'colorHex': null,
      }, 'user-123');

      expect(result['color_hex'], null);
    });

    test('does not include transaction-only fields', () {
      final result = dataSource.mapForSupabase('category', {
        'id': 'cat-1',
        'name': 'Food',
        'colorHex': '#FF9800',
      }, 'user-123');

      expect(result.containsKey('amount_minor'), false);
      expect(result.containsKey('occurred_at'), false);
    });
  });

  group('mapForSupabase - unknown entity type', () {
    test('an unrecognized entityType returns the local payload unchanged', () {
      final local = {'id': 'x-1', 'someField': 'value'};

      final result = dataSource.mapForSupabase(
        'something-new',
        local,
        'user-123',
      );

      expect(result, local);
      // Deliberately not renamed and no user_id stamped -- this is the
      // fallback branch (`default: return local;`), included so a future
      // entity type isn't silently mis-synced without a test noticing.
      expect(result.containsKey('user_id'), false);
    });
  });
}
