import 'package:stockflow/core/result.dart';
import 'package:stockflow/transactions/domain/repositories/category_repository.dart';

class DeleteCategoryUseCase {
  DeleteCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  Future<Result<int>> call(String id) {
    return _repository.deleteCategory(id);
  }
}
