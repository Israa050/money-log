import 'package:stockflow/transactions/domain/entities/category_entity.dart';
import 'package:stockflow/transactions/domain/repositories/category_repository.dart';

class GetCategoriesUseCase {
  GetCategoriesUseCase(this._repository);

  final CategoryRepository _repository;

  Future<List<CategoryEntity>> call() {
    return _repository.getCategories();
  }
}
