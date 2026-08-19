import 'package:drift/drift.dart';
import 'package:stockflow/core/result.dart';
import 'package:stockflow/transactions/data/transactions_data_source.dart';
import 'package:stockflow/transactions/domain/entities/category_entity.dart';
import 'package:stockflow/transactions/domain/entities/category_total_entity.dart';
import 'package:stockflow/transactions/domain/repositories/category_repository.dart';
import 'package:uuid/uuid.dart';

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
  Stream<List<CategoryEntity>> watchCategories() {
    return dataSource.watchAllCategories.map(
      (rows) => rows.map(_toEntity).toList(),
    );
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

  @override
  Future<Result<void>> addCategory({
    required String name,
    String? colorHex,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Failure('Category name cannot be empty');
    }

    final existing = await getCategoryByName(trimmedName);
    if (existing != null) {
      return const Failure('A category with this name already exists');
    }

    final entry = CategoriesCompanion.insert(
      id: const Uuid().v4(),
      name: trimmedName,
      colorHex: Value(colorHex),
    );
    try {
      await dataSource.addCategory(entry);
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<int>> deleteCategory(String id) async {
    try {
      final result = await dataSource.deleteCategory(id);
      return Success(result);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<CategoryEntity?> getCategoryByName(String name) async {
    final row = await dataSource.findCategoryByName(name);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<Result<void>> updateCategory({
    required String id,
    required String name,
    String? colorHex,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Failure('Category name cannot be empty');
    }

    final existing = await getCategoryByName(trimmedName);
    if (existing != null && existing.id != id) {
      return const Failure('A category with this name already exists');
    }

    final entry = CategoriesCompanion(
      id: Value(id),
      name: Value(trimmedName),
      colorHex: Value(colorHex),
    );
    try {
      await dataSource.updateCategory(entry);
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}
