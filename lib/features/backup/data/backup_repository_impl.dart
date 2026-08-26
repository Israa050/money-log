import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path;
import 'package:stockflow/core/result.dart';
import 'package:stockflow/features/backup/data/export_serializer.dart';
import 'package:stockflow/features/backup/domain/backup_repository.dart';
import 'package:stockflow/features/backup/domain/entities/exportable_source.dart';
import 'package:stockflow/features/backup/domain/entities/exported_file.dart';

class BackupRepositoryImpl extends BackupRepository {
  final List<ExportableSource> _sources;

  BackupRepositoryImpl({required List<ExportableSource> sources})
    : _sources = sources;

  @override
  Future<Result<ExportedFile>> exportToJson() async {
    try {
      final sourceData = <String, List<Map<String, Object?>>>{};
      for (final source in _sources) {
        sourceData[source.key] = await source.exportRows();
      }
      final jsonString = await Isolate.run(() => encodeExport(sourceData));

      final dir = await path.getTemporaryDirectory();
      final fileName =
          'moneylog-export-${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File(path.join(dir.path, fileName));
      await file.writeAsString(jsonString);

      final counts = sourceData.map((key, rows) => MapEntry(key, rows.length));
      return Success(
        ExportedFile(
          path: file.path,
          byteSize: await file.length(),
          countsByKey: counts,
        ),
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }
}
