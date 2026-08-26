import 'package:stockflow/core/result.dart';
import 'package:stockflow/features/categories/domain/entities/category_entity.dart';
import 'package:stockflow/features/categories/domain/entities/category_total_entity.dart';

abstract class CategoryRepository {
  Stream<List<CategoryEntity>> watchCategories();

  /// One-shot snapshot (vs. the live stream above) -- used by the
  /// export/backup feature, which needs a single read, not a subscription.
  Future<List<CategoryEntity>> getAllCategoriesOnce();

  Stream<List<CategoryTotalEntity>> watchCategoryTotals();

  Future<Result<void>> addCategory({required String name, String? colorHex});

  Future<Result<int>> deleteCategory(String id);

  Future<Result<void>> updateCategory({
    required String id,
    required String name,
    String? colorHex,
  });

  Future<CategoryEntity?> getCategoryByName(String name);
}
