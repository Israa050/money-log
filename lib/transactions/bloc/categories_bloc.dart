import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/transactions/domain/entities/category_entity.dart';
import 'package:stockflow/transactions/domain/usecases/add_category_usecase.dart';
import 'package:stockflow/transactions/domain/usecases/delete_category_usecase.dart';
import 'package:stockflow/transactions/domain/usecases/update_category_usecase.dart';
import 'package:stockflow/transactions/domain/usecases/watch_categories_usecase.dart';

part 'categories_event.dart';
part 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  CategoriesBloc({
    required this.watchCategoriesUseCase,
    required this.addCategoryUseCase,
    required this.updateCategoryUseCase,
    required this.deleteCategoryUseCase,
  }) : super(CategoriesInitial()) {
    on<CategoriesStarted>(_onStarted);
    on<_CategoriesUpdated>(_onCategoriesUpdated);
    on<_CategoriesFailed>(_onCategoriesFailed);
    on<AddCategoryEvent>(_onAddCategory);
    on<UpdateCategoryEvent>(_onUpdateCategory);
    on<DeleteCategoryEvent>(_onDeleteCategory);
  }

  final WatchCategoriesUseCase watchCategoriesUseCase;
  final AddCategoryUseCase addCategoryUseCase;
  final UpdateCategoryUseCase updateCategoryUseCase;
  final DeleteCategoryUseCase deleteCategoryUseCase;

  StreamSubscription<List<CategoryEntity>>? _subscription;

  void _onStarted(CategoriesStarted event, Emitter<CategoriesState> emit) {
    if (_subscription != null) return;
    _subscription = watchCategoriesUseCase().listen(
      (items) => add(_CategoriesUpdated(data: items)),
      onError: (Object e) => add(_CategoriesFailed(message: e.toString())),
    );
  }

  void _onCategoriesUpdated(
    _CategoriesUpdated event,
    Emitter<CategoriesState> emit,
  ) {
    emit(CategoriesLoaded(data: event.data));
  }

  void _onCategoriesFailed(
    _CategoriesFailed event,
    Emitter<CategoriesState> emit,
  ) {
    emit(CategoriesError(message: event.message, previousData: _currentData));
  }

  Future<void> _onAddCategory(
    AddCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    final result = await addCategoryUseCase(
      name: event.name,
      colorHex: event.colorHex,
    );
    result.when(
      success: (_) {},
      failure: (message) =>
          emit(CategoriesError(message: message, previousData: _currentData)),
    );
  }

  Future<void> _onUpdateCategory(
    UpdateCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    final result = await updateCategoryUseCase(
      id: event.id,
      name: event.name,
      colorHex: event.colorHex,
    );
    result.when(
      success: (_) {},
      failure: (message) =>
          emit(CategoriesError(message: message, previousData: _currentData)),
    );
  }

  Future<void> _onDeleteCategory(
    DeleteCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    final result = await deleteCategoryUseCase(event.id);
    result.when(
      success: (_) {},
      failure: (message) =>
          emit(CategoriesError(message: message, previousData: _currentData)),
    );
  }

  List<CategoryEntity> get _currentData => switch (state) {
    CategoriesLoaded(:final data) => data,
    CategoriesError(:final previousData) => previousData,
    CategoriesInitial() => <CategoryEntity>[],
  };

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
