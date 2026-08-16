import 'package:stockflow/transactions/data/transactions_data_source.dart';
import 'package:stockflow/transactions/domain/entities/category_entity.dart';
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
}
