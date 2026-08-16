import 'package:stockflow/core/result.dart';
import 'package:stockflow/transactions/domain/entities/transaction_entity.dart';
import 'package:stockflow/transactions/domain/entities/transaction_type.dart';

abstract class TransactionsRepository {
  Stream<List<TransactionEntity>> getAllTransactions();

  Stream<int> watchBalance();

  Future<Result<void>> addTransaction({
    required int amountMinor,
    required TransactionType type,
    String? note,
    String? categoryId,
  });

  Future<Result<int>> deleteTransaction(String id);
}
