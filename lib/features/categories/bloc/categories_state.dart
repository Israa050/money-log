part of 'categories_bloc.dart';

@immutable
sealed class CategoriesState {}

final class CategoriesInitial extends CategoriesState {}

final class CategoriesLoaded extends CategoriesState {
  final List<CategoryEntity> data;

  CategoriesLoaded({required this.data});
}

final class CategoriesError extends CategoriesState {
  final String message;
  final List<CategoryEntity> previousData;

  CategoriesError({required this.message, required this.previousData});
}
