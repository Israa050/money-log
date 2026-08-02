part of 'transactions_bloc.dart';

@immutable
sealed class TransactionsEvent {}

final class AppLaunchEvent extends TransactionsEvent {}

final class AddTransactionEvent extends TransactionsEvent {
  final String item;

  AddTransactionEvent({required this.item});
}

final class DeleteTransactionEvent extends TransactionsEvent {
  final int id;

  DeleteTransactionEvent({required this.id});
}
