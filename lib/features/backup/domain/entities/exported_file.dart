class ExportedFile {
  final String path;
  final int byteSize;
  final Map<String, int> countsByKey;

  ExportedFile({
    required this.path,
    required this.byteSize,
    required this.countsByKey,
  });
}
