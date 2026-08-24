import 'package:flutter/material.dart';
import 'package:stockflow/features/categories/domain/entities/category_entity.dart';
import 'package:stockflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:stockflow/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:stockflow/features/transactions/presentation/widgets/transactions_empty_state.dart';

/// Scrollable list of transactions, or an empty-state placeholder when
/// [data] is empty.
class TransactionsList extends StatelessWidget {
  const TransactionsList({
    super.key,
    required this.data,
    required this.onDelete,
    required this.categories,
  });

  final List<TransactionEntity> data;
  final ValueChanged<TransactionEntity> onDelete;
  final List<CategoryEntity> categories;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const TransactionsEmptyState();

    final categoriesById = {for (final c in categories) c.id: c};

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: data.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final transaction = data[index];
        return TransactionTile(
          transaction: transaction,
          onDelete: () => onDelete(transaction),
          category: categoriesById[transaction.categoryId],
        );
      },
    );
  }
}
