import 'package:flutter/material.dart';
import 'package:stockflow/core/theme/app_colors.dart';

/// Placeholder shown when there are no transactions yet.
class TransactionsEmptyState extends StatelessWidget {
  const TransactionsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: colors.inkFaint.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: colors.inkSoft,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add your first one',
            style: TextStyle(fontSize: 12.5, color: colors.inkFaint),
          ),
        ],
      ),
    );
  }
}
