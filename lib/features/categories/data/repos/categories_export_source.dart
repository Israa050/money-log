import 'package:stockflow/features/backup/domain/entities/exportable_source.dart';
import 'package:stockflow/features/categories/domain/entities/category_entity.dart';
import 'package:stockflow/features/categories/domain/repositories/category_repository.dart';

class CategoriesExportSource extends ExportableSource {
  final CategoryRepository categoryRepository;

  CategoriesExportSource({required this.categoryRepository});

  @override
  String get key => 'categories';

  @override
  Future<List<Map<String, Object?>>> exportRows() async {
    final categories = await categoryRepository.getAllCategoriesOnce();
    return categories.map(_toMap).toList();
  }

  Map<String, Object?> _toMap(CategoryEntity c) {
    return {'id': c.id, 'name': c.name, 'colorHex': c.colorHex};
  }
}
