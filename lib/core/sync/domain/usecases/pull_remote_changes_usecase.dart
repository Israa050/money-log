import 'package:stockflow/core/result.dart';
import 'package:stockflow/core/sync/domain/repositories/sync_repository.dart';

class PullRemoteChangesUseCase {
  PullRemoteChangesUseCase(this._repository);

  final SyncRepository _repository;

  Future<Result<int>> call() {
    return _repository.pullRemoteChanges();
  }
}
