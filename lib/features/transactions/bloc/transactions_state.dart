part of 'transactions_bloc.dart';

@immutable
sealed class TransactionsState {}

final class TransactionsInitial extends TransactionsState {}

final class Loaded extends TransactionsState {
  final List<TransactionEntity> data;
  final List<CategoryEntity> categories;

  Loaded({required this.data, required this.categories});
}

final class TransactionsError extends TransactionsState {
  final String message;
  final List<TransactionEntity> previousData;

  TransactionsError({required this.message, required this.previousData});
}
