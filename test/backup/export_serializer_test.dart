import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stockflow/features/backup/data/export_serializer.dart';

void main() {
  // A representative two-source payload reused across cases.
  final sampleData = <String, List<Map<String, Object?>>>{
    'transactions': [
      {'id': 't1', 'amountMinor': 500},
      {'id': 't2', 'amountMinor': 250},
    ],
    'categories': [
      {'id': 'c1', 'name': 'Food'},
    ],
  };

  group('buildEnvelope', () {
    test('stamps the fixed format metadata', () {
      final envelope = buildEnvelope(sampleData);

      expect(envelope['formatVersion'], 1);
      expect(envelope['appVersion'], '0.4.0');
      expect(envelope['schemaVersion'], 4);
    });

    test('exportedAt is a valid UTC ISO-8601 instant', () {
      final envelope = buildEnvelope(sampleData);

      final exportedAt = envelope['exportedAt'] as String;
      expect(exportedAt, endsWith('Z'));

      final parsed = DateTime.parse(exportedAt);
      expect(parsed.isUtc, isTrue);
      // Sanity: it's "now", not some epoch default.
      expect(
        parsed.difference(DateTime.now().toUtc()).abs(),
        lessThan(const Duration(minutes: 1)),
      );
    });

    test('counts maps each source key to its row-list length', () {
      final envelope = buildEnvelope(sampleData);

      expect(envelope['counts'], {'transactions': 2, 'categories': 1});
    });

    test('source data is spread onto the envelope at the top level', () {
      final envelope = buildEnvelope(sampleData);

      expect(envelope['transactions'], same(sampleData['transactions']));
      expect(envelope['categories'], same(sampleData['categories']));
    });

    test('a source with zero rows -> count 0, key still present as []', () {
      final envelope = buildEnvelope({
        'transactions': [],
        'categories': [
          {'id': 'c1'},
        ],
      });

      expect(envelope['counts'], {'transactions': 0, 'categories': 1});
      expect(envelope['transactions'], isEmpty);
    });

    test('empty sourceData -> empty counts, metadata still present', () {
      final envelope = buildEnvelope({});

      expect(envelope['counts'], isEmpty);
      expect(envelope['formatVersion'], 1);
      expect(envelope['schemaVersion'], 4);
      expect(envelope['exportedAt'], isA<String>());
    });

    test('counts does not collide with a source literally named "counts"', () {
      // Documents current behaviour: a source key of "counts" is spread
      // AFTER the computed counts entry, so the source data wins.
      final envelope = buildEnvelope({
        'counts': [
          {'id': 'x'},
        ],
      });

      expect(envelope['counts'], [
        {'id': 'x'},
      ]);
    });
  });

  group('encodeExport', () {
    test('returns a JSON string that decodes back to the envelope', () {
      final decoded =
          jsonDecode(encodeExport(sampleData)) as Map<String, Object?>;

      expect(decoded['formatVersion'], 1);
      expect(decoded['appVersion'], '0.4.0');
      expect(decoded['schemaVersion'], 4);
      expect(decoded['counts'], {'transactions': 2, 'categories': 1});
      expect(decoded['transactions'], sampleData['transactions']);
      expect(decoded['categories'], sampleData['categories']);
      expect(DateTime.parse(decoded['exportedAt'] as String).isUtc, isTrue);
    });

    test('produces valid JSON for an empty payload', () {
      final decoded = jsonDecode(encodeExport({})) as Map<String, Object?>;

      expect(decoded['counts'], isEmpty);
      expect(decoded['formatVersion'], 1);
    });

    test('nested row values survive the JSON round-trip unchanged', () {
      final data = {
        'transactions': [
          {
            'id': 't1',
            'note': null,
            'amountMinor': 1234,
            'tags': ['a', 'b'],
          },
        ],
      };

      final decoded = jsonDecode(encodeExport(data)) as Map<String, Object?>;

      expect(decoded['transactions'], data['transactions']);
    });
  });
}
