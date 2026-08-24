import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/features/categories/domain/entities/category_entity.dart';
import 'package:stockflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:stockflow/features/transactions/domain/entities/transaction_type.dart';
import 'package:stockflow/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:stockflow/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:stockflow/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:stockflow/features/categories/domain/usecases/watch_categories_usecase.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  TransactionsBloc({
    required this.getTransactionsUseCase,
    required this.addTransactionUseCase,
    required this.deleteTransactionUseCase,
    required this.watchCategoriesUseCase,
  }) : super(TransactionsInitial()) {
    on<AppLaunchEvent>(_onLaunch);
    on<_TransactionsUpdated>(_onTransactionsUpdated);
    on<_TransactionsFailed>(_onTransactionsFailed);
    on<_CategoriesUpdated>(_onCategoriesUpdated);
    on<AddTransactionEvent>(_onAddTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
  }

  final GetTransactionsUseCase getTransactionsUseCase;
  final AddTransactionUseCase addTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;
  final WatchCategoriesUseCase watchCategoriesUseCase;

  StreamSubscription<List<TransactionEntity>>? _subscription;
  StreamSubscription<List<CategoryEntity>>? _categoriesSubscription;
  List<CategoryEntity> _categories = [];

  Future<void> _onLaunch(
    AppLaunchEvent event,
    Emitter<TransactionsState> emit,
  ) async {
    if (_subscription != null) return;
    _categoriesSubscription = watchCategoriesUseCase().listen(
      (items) => add(_CategoriesUpdated(data: items)),
    );
    _subscription = getTransactionsUseCase().listen(
      (items) => add(_TransactionsUpdated(data: items)),
      onError: (Object e) => add(_TransactionsFailed(message: e.toString())),
    );
  }

  void _onTransactionsUpdated(
    _TransactionsUpdated event,
    Emitter<TransactionsState> emit,
  ) {
    emit(Loaded(data: event.data, categories: _categories));
  }

  void _onTransactionsFailed(
    _TransactionsFailed event,
    Emitter<TransactionsState> emit,
  ) {
    emit(TransactionsError(message: event.message, previousData: _currentData));
  }

  void _onCategoriesUpdated(
    _CategoriesUpdated event,
    Emitter<TransactionsState> emit,
  ) {
    _categories = event.data;
    // Transactions haven't loaded yet: wait for _onTransactionsUpdated
    // rather than emitting Loaded with a fake-empty transaction list.
    if (state is TransactionsInitial) return;
    emit(Loaded(data: _currentData, categories: _categories));
  }

  Future<void> _onAddTransaction(
    AddTransactionEvent event,
    Emitter<TransactionsState> emit,
  ) async {
    final addResult = await addTransactionUseCase(
      amountMinor: event.amountMinor,
      type: event.type,
      note: event.note,
      categoryId: event.categoryId,
    );
    addResult.when(
      success: (_) {},
      failure: (message) =>
          emit(TransactionsError(message: message, previousData: _currentData)),
    );
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<TransactionsState> emit,
  ) async {
    final deleteResult = await deleteTransactionUseCase(event.id);
    deleteResult.when(
      success: (_) {},
      failure: (message) =>
          emit(TransactionsError(message: message, previousData: _currentData)),
    );
  }

  List<TransactionEntity> get _currentData => switch (state) {
    Loaded(:final data) => data,
    TransactionsError(:final previousData) => previousData,
    TransactionsInitial() => <TransactionEntity>[],
  };

  @override
  Future<void> close() {
    _subscription?.cancel();
    _categoriesSubscription?.cancel();
    return super.close();
  }
}
