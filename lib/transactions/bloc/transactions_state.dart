part of 'transactions_bloc.dart';

@immutable
sealed class TransactionsState {}

final class TransactionsInitial extends TransactionsState {}

final class Loading extends TransactionsState {
  final List<Transaction> previousData;

  Loading({required this.previousData});
}

final class Loaded extends TransactionsState {
  final List<Transaction> data;

  Loaded({required this.data});
}

final class TransactionsError extends TransactionsState {
  final String message;
  final List<Transaction> previousData;

  TransactionsError({required this.message, required this.previousData});
}
