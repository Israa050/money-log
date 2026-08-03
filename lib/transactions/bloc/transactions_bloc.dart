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
    on<AddTransactionEvent>(_onAddTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
  }

  final TransactionsRepository transactionsRepository;

  Future<void> _onLaunch(
    AppLaunchEvent event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(Loading(previousData: []));
    final result = await transactionsRepository.getAllTransactions();
    result.when(
      success: (data) => emit(Loaded(data: data)),
      failure: (message) =>
          emit(TransactionsError(message: message, previousData: [])),
    );
  }

  Future<void> _onAddTransaction(
    AddTransactionEvent event,
    Emitter<TransactionsState> emit,
  ) async {
    final previousData = state is Loaded
        ? (state as Loaded).data
        : <Transaction>[];
    emit(Loading(previousData: previousData));

    final entry = transactionsRepository.newTransactionEntry(
      amountMinor: event.amountMinor,
      type: event.type,
      note: event.note,
    );
    final addResult = await transactionsRepository.addTransaction(entry);
    await addResult.when(
      success: (_) async => _refresh(emit, previousData),
      failure: (message) async => emit(
        TransactionsError(message: message, previousData: previousData),
      ),
    );
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<TransactionsState> emit,
  ) async {
    final previousData = state is Loaded
        ? (state as Loaded).data
        : <Transaction>[];
    emit(Loading(previousData: previousData));

    final deleteResult = await transactionsRepository.deleteTransaction(
      event.id,
    );
    await deleteResult.when(
      success: (_) async => _refresh(emit, previousData),
      failure: (message) async => emit(
        TransactionsError(message: message, previousData: previousData),
      ),
    );
  }

  Future<void> _refresh(
    Emitter<TransactionsState> emit,
    List<Transaction> previousData,
  ) async {
    final result = await transactionsRepository.getAllTransactions();
    result.when(
      success: (data) => emit(Loaded(data: data)),
      failure: (message) =>
          emit(TransactionsError(message: message, previousData: previousData)),
    );
  }
}
