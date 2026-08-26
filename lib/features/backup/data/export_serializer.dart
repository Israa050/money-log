import 'dart:convert';

Map<String, Object?> buildEnvelope(
  Map<String, List<Map<String, Object?>>> sourceData,
) {
  return {
    'formatVersion': 1,
    'appVersion': '0.4.0',
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'schemaVersion': 4,
    'counts': sourceData.map((key, rows) => MapEntry(key, rows.length)),
    ...sourceData,
  };
}

String encodeExport(Map<String, List<Map<String, Object?>>> sourceData) {
  final result = buildEnvelope(sourceData);
  return jsonEncode(result);
}
