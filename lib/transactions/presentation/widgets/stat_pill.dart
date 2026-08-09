import 'package:flutter/material.dart';
import 'package:stockflow/core/theme/app_colors.dart';
import 'package:stockflow/transactions/presentation/format.dart';

/// Small income/expense stat tile shown inside the balance summary card.
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconWash,
    required this.label,
    required this.amountMinor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconWash;
  final String label;
  final int amountMinor;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.lineSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: iconWash, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10.5, color: colors.inkFaint),
                ),
                const SizedBox(height: 1),
                Text(
                  formatAmountMinor(amountMinor),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
