import 'package:stockflow/core/result.dart';
import 'package:stockflow/features/backup/domain/backup_repository.dart';
import 'package:stockflow/features/backup/domain/entities/exported_file.dart';

class ExportDataUseCase {
  ExportDataUseCase(this._repository);

  final BackupRepository _repository;

  Future<Result<ExportedFile>> call() {
    return _repository.exportToJson();
  }
}
