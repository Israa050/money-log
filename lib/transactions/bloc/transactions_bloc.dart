import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/transactions/data/models/transactions.dart';
import 'package:stockflow/transactions/data/repos/transactions_repository.dart';
import 'package:stockflow/transactions/data/transactions_data_source.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  TransactionsBloc({required this.transactionsRepository})
    : super(TransactionsInitial()) {
    on<AppLaunchEvent>(_onLaunch);
    on<_TransactionsUpdated>(_onTransactionsUpdated);
    on<AddTransactionEvent>(_onAddTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
  }

  final TransactionsRepository transactionsRepository;
  StreamSubscription<List<Transaction>>? _subscription;

  void _onLaunch(AppLaunchEvent event, Emitter<TransactionsState> emit) {
    if (_subscription != null) return;
    _subscription = transactionsRepository.getAllTransactions().listen(
      (items) => add(_TransactionsUpdated(data: items)),
    );
  }

  void _onTransactionsUpdated(
    _TransactionsUpdated event,
    Emitter<TransactionsState> emit,
  ) {
    emit(Loaded(data: event.data));
  }

  Future<void> _onAddTransaction(
    AddTransactionEvent event,
    Emitter<TransactionsState> emit,
  ) async {
    final entry = transactionsRepository.newTransactionEntry(
      amountMinor: event.amountMinor,
      type: event.type,
      note: event.note,
    );
    final addResult = await transactionsRepository.addTransaction(entry);
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
    final deleteResult = await transactionsRepository.deleteTransaction(
      event.id,
    );
    deleteResult.when(
      success: (_) {},
      failure: (message) =>
          emit(TransactionsError(message: message, previousData: _currentData)),
    );
  }

  List<Transaction> get _currentData => switch (state) {
    Loaded(:final data) => data,
    TransactionsError(:final previousData) => previousData,
    TransactionsInitial() => <Transaction>[],
  };

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
