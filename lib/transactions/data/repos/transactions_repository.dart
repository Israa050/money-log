import 'package:drift/drift.dart';
import 'package:stockflow/core/result.dart';
import 'package:stockflow/transactions/data/models/transactions.dart';
import 'package:stockflow/transactions/data/transactions_data_source.dart';
import 'package:uuid/uuid.dart';

class TransactionsRepository {
  final TransactionsDataSource dataSource;

  TransactionsRepository({required this.dataSource});

  TransactionsCompanion newTransactionEntry({
    required int amountMinor,
    required TransactionType type,
    String? note,
  }) {
    return TransactionsCompanion.insert(
      id: const Uuid().v4(),
      amountMinor: amountMinor,
      type: type,
      note: Value(note),
    );
  }

  Stream<List<Transaction>> getAllTransactions() {
    return dataSource.allTransactions;
  }

  Future<Result<int>> addTransaction(TransactionsCompanion entry) async {
    try {
      final result = await dataSource.addTransaction(entry);
      return Success(result);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Future<Result<int>> deleteTransaction(String id) async {
    try {
      final result = await dataSource.deleteTransaction(id);
      return Success(result);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}
