import 'package:stockflow/transactions/domain/entities/category_entity.dart';
import 'package:stockflow/transactions/domain/entities/category_total_entity.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getCategories();

  Stream<List<CategoryTotalEntity>> watchCategoryTotals();
}
