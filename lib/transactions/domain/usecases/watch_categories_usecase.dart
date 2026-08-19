import 'package:stockflow/transactions/domain/entities/category_entity.dart';
import 'package:stockflow/transactions/domain/repositories/category_repository.dart';

class WatchCategoriesUseCase {
  WatchCategoriesUseCase(this._repository);

  final CategoryRepository _repository;

  Stream<List<CategoryEntity>> call() {
    return _repository.watchCategories();
  }
}
