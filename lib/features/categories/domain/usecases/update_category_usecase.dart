import 'package:stockflow/core/result.dart';
import 'package:stockflow/features/categories/domain/repositories/category_repository.dart';

class UpdateCategoryUseCase {
  UpdateCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  Future<Result<void>> call({
    required String id,
    required String name,
    String? colorHex,
  }) {
    return _repository.updateCategory(id: id, name: name, colorHex: colorHex);
  }
}
