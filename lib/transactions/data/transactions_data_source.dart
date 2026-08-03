

import 'package:drift/drift.dart';
import 'package:stockflow/transactions/data/models/transactions.dart';

part 'transactions_data_source.g.dart';

@DriftDatabase(tables: [Transactions])
class TransactionsDataSource extends _$TransactionsDataSource {
  TransactionsDataSource(super.executor);

  @override
  int get schemaVersion => 1;

  Future<List<Transaction>> get allTransactions => select(transactions).get();

  Future<int> addTransaction(TransactionsCompanion entry){
    return into(transactions).insert(entry);
  }

  Future<int> deleteTransaction(String id) {
    return (delete(transactions)..where((item) => item.id.equals(id))).go();
  }
}