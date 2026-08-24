import 'package:stockflow/features/categories/domain/entities/category_total_entity.dart';
import 'package:stockflow/features/categories/domain/repositories/category_repository.dart';

class WatchCategoryTotalsUsecase {
  final CategoryRepository categoryRepository;

  WatchCategoryTotalsUsecase({required this.categoryRepository});

  Stream<List<CategoryTotalEntity>> watchCategoryTotals() {
    return categoryRepository.watchCategoryTotals();
  }
}
