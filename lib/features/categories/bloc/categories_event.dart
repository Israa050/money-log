part of 'categories_bloc.dart';

@immutable
sealed class CategoriesEvent {}

final class CategoriesStarted extends CategoriesEvent {}

final class _CategoriesUpdated extends CategoriesEvent {
  final List<CategoryEntity> data;
  _CategoriesUpdated({required this.data});
}

final class _CategoriesFailed extends CategoriesEvent {
  final String message;
  _CategoriesFailed({required this.message});
}

final class AddCategoryEvent extends CategoriesEvent {
  final String name;
  final String? colorHex;

  AddCategoryEvent({required this.name, this.colorHex});
}

final class UpdateCategoryEvent extends CategoriesEvent {
  final String id;
  final String name;
  final String? colorHex;

  UpdateCategoryEvent({required this.id, required this.name, this.colorHex});
}

final class DeleteCategoryEvent extends CategoriesEvent {
  final String id;

  DeleteCategoryEvent({required this.id});
}
