import 'package:flutter/material.dart';
import 'package:stockflow/transactions/data/transactions_data_source.dart'
    show Transaction;
import 'package:stockflow/transactions/presentation/widgets/transaction_tile.dart';
import 'package:stockflow/transactions/presentation/widgets/transactions_empty_state.dart';

/// Scrollable list of transactions, or an empty-state placeholder when
/// [data] is empty.
class TransactionsList extends StatelessWidget {
  const TransactionsList({
    super.key,
    required this.data,
    required this.onDelete,
  });

  final List<Transaction> data;
  final ValueChanged<Transaction> onDelete;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const TransactionsEmptyState();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: data.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final transaction = data[index];
        return TransactionTile(
          transaction: transaction,
          onDelete: () => onDelete(transaction),
        );
      },
    );
  }
}
