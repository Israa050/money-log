import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/transactions/data/repos/fake_repository.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  TransactionsBloc({required this.fakeRepository})
    : super(TransactionsInitial()) {
    on<AppLaunchEvent>(_onLaunch);
    on<AddTransactionEvent>(_onAddTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
  }

  final FakeRepository fakeRepository;

  Future<void> _onLaunch(
    AppLaunchEvent event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(Loading(previousData: []));
    try {
      final result = await fakeRepository.getTransactions();
      emit(Loaded(data: result));
    } catch (e) {
      emit(TransactionsError(message: e.toString(), previousData: []));
    }
  }

  Future<void> _onAddTransaction(
    AddTransactionEvent event,
    Emitter<TransactionsState> emit,
  ) async {
    final previousData = state is Loaded ? (state as Loaded).data : <String>[];
    emit(Loading(previousData: previousData));
    try {
      final result = await fakeRepository.addTransaction(event.item);
      emit(Loaded(data: result));
    } catch (e) {
      emit(
        TransactionsError(message: e.toString(), previousData: previousData),
      );
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<TransactionsState> emit,
  ) async {
    final previousData = state is Loaded ? (state as Loaded).data : <String>[];
    emit(Loading(previousData: previousData));
    try {
      final result = await fakeRepository.deleteTransaction(event.id);
      emit(Loaded(data: result));
    } catch (e) {
      emit(
        TransactionsError(message: e.toString(), previousData: previousData),
      );
    }
  }
}
