part of 'transactions_bloc.dart';

@immutable
sealed class TransactionsEvent {}

final class AppLaunchEvent extends TransactionsEvent {}

final class _TransactionsUpdated extends TransactionsEvent {
  final List<Transaction> data;
  _TransactionsUpdated({required this.data});
}

final class AddTransactionEvent extends TransactionsEvent {
  final int amountMinor;
  final TransactionType type;
  final String? note;

  AddTransactionEvent({
    required this.amountMinor,
    required this.type,
    this.note,
  });
}

final class DeleteTransactionEvent extends TransactionsEvent {
  final String id;

  DeleteTransactionEvent({required this.id});
}
