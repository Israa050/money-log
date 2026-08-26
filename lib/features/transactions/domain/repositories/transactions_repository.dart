import 'package:stockflow/core/result.dart';
import 'package:stockflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:stockflow/features/transactions/domain/entities/transaction_type.dart';

abstract class TransactionsRepository {
  Stream<List<TransactionEntity>> getAllTransactions();

  /// One-shot snapshot (vs. the live stream above) -- used by the
  /// export/backup feature, which needs a single read, not a subscription.
  Future<List<TransactionEntity>> getAllTransactionsOnce();

  Stream<int> watchBalance();

  Future<Result<void>> addTransaction({
    required int amountMinor,
    required TransactionType type,
    String? note,
    String? categoryId,
  });

  Future<Result<int>> deleteTransaction(String id);
}
