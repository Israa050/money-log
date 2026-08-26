abstract class ExportableSource {
  String get key;
  Future<List<Map<String, Object?>>> exportRows();
}
