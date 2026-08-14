part of 'transactions_bloc.dart';

@immutable
sealed class TransactionsState {}

final class TransactionsInitial extends TransactionsState {}

final class Loaded extends TransactionsState {
  final List<TransactionEntity> data;

  Loaded({required this.data});
}

final class TransactionsError extends TransactionsState {
  final String message;
  final List<TransactionEntity> previousData;

  TransactionsError({required this.message, required this.previousData});
}
