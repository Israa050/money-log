import 'package:drift/drift.dart';
import 'package:stockflow/core/result.dart';
import 'package:stockflow/transactions/data/transactions_data_source.dart';
import 'package:stockflow/transactions/domain/entities/transaction_entity.dart';
import 'package:stockflow/transactions/domain/entities/transaction_type.dart';
import 'package:stockflow/transactions/domain/repositories/transactions_repository.dart';
import 'package:uuid/uuid.dart';

class TransactionsRepositoryImpl extends TransactionsRepository {
  final TransactionsDataSource dataSource;

  TransactionsRepositoryImpl({required this.dataSource});

  TransactionEntity _toEntity(Transaction row) {
    return TransactionEntity(
      id: row.id,
      amountMinor: row.amountMinor,
      type: row.type,
      note: row.note ?? '',
      timestamp: row.occurredTime,
      categoryId: row.categoryId,
    );
  }

  @override
  Stream<List<TransactionEntity>> getAllTransactions() {
    return dataSource.allTransactions.map(
      (rows) => rows.map(_toEntity).toList(),
    );
  }

  @override
  Stream<int> watchBalance() {
    return dataSource.balance;
  }

  @override
  Future<Result<void>> addTransaction({
    required int amountMinor,
    required TransactionType type,
    String? note,
    String? categoryId,
  }) async {
    final entry = TransactionsCompanion.insert(
      id: const Uuid().v4(),
      amountMinor: amountMinor,
      type: type,
      note: Value(note),
      categoryId: Value(categoryId),
    );
    try {
      await dataSource.addTransaction(entry);
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<int>> deleteTransaction(String id) async {
    try {
      final result = await dataSource.deleteTransaction(id);
      return Success(result);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}
