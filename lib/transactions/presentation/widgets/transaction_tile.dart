import 'package:flutter/material.dart';
import 'package:stockflow/core/theme/app_colors.dart';
import 'package:stockflow/transactions/domain/entities/transaction_entity.dart';
import 'package:stockflow/transactions/domain/entities/transaction_type.dart';
import 'package:stockflow/transactions/presentation/format.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onDelete,
  });

  final TransactionEntity transaction;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? colors.income : colors.expense;
    final wash = isIncome ? colors.incomeWash : colors.expenseWash;
    final sign = isIncome ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Dismissible(
        key: ValueKey(transaction.id),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: colors.expenseWash,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Icon(Icons.delete_outline, color: colors.expense),
        ),
        onDismissed: (_) => onDelete(),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.lineSoft),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: wash, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(
                  isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      transaction.note?.isNotEmpty == true
                          ? transaction.note!
                          : (isIncome ? 'Income' : 'Expense'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      formatDate(transaction.timestamp),
                      style: TextStyle(fontSize: 11.5, color: colors.inkFaint),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$sign${formatAmountMinor(transaction.amountMinor)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
