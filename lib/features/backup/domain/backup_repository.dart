import 'package:stockflow/core/result.dart';
import 'package:stockflow/features/backup/domain/entities/exported_file.dart';

abstract class BackupRepository {
  Future<Result<ExportedFile>> exportToJson();
}
