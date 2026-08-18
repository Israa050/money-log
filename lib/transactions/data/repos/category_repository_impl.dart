import 'package:stockflow/transactions/data/transactions_data_source.dart';
import 'package:stockflow/transactions/domain/entities/category_entity.dart';
import 'package:stockflow/transactions/domain/entities/category_total_entity.dart';
import 'package:stockflow/transactions/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl extends CategoryRepository {
  final TransactionsDataSource dataSource;

  CategoryRepositoryImpl({required this.dataSource});

  CategoryEntity _toEntity(Category category) {
    return CategoryEntity(
      id: category.id,
      name: category.name,
      colorHex: category.colorHex,
    );
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final rows = await dataSource.allCategories;
    return rows.map(_toEntity).toList();
  }

  @override
  Stream<List<CategoryTotalEntity>> watchCategoryTotals() {
    return dataSource.categoryTotals.map(
      (rows) => rows.map(_toCategoryTotalEntity).toList(),
    );
  }

  CategoryTotalEntity _toCategoryTotalEntity(CategoryTotalRow row) {
    return CategoryTotalEntity(
      id: row.categoryId ?? 'Uncategorized',
      name: row.categoryName ?? 'Uncategorized',
      colorHex: row.colorHex,
      totalMinor: row.totalMinor,
    );
  }
}
