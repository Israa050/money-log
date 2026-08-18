import 'package:stockflow/transactions/domain/entities/transaction_type.dart';

class TransactionEntity {
  final String id;
  final int amountMinor;
  final TransactionType type;
  final String? note;
  final DateTime timestamp;
  final String? categoryId;

  TransactionEntity({
    required this.id,
    required this.amountMinor,
    required this.type,
    required this.note,
    required this.timestamp,
    required this.categoryId,
  });
}
