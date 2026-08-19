import 'package:stockflow/core/result.dart';
import 'package:stockflow/transactions/domain/repositories/category_repository.dart';

class AddCategoryUseCase {
  AddCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  Future<Result<void>> call({required String name, String? colorHex}) {
    return _repository.addCategory(name: name, colorHex: colorHex);
  }
}
