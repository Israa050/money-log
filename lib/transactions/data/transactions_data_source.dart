import 'package:drift/drift.dart';
import 'package:stockflow/transactions/data/models/categories.dart';
import 'package:stockflow/transactions/data/models/transactions.dart';
import 'package:stockflow/transactions/domain/entities/transaction_type.dart';

part 'transactions_data_source.g.dart';

@DriftDatabase(tables: [Transactions, Categories])
class TransactionsDataSource extends _$TransactionsDataSource {
  TransactionsDataSource(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(categories);
        await m.addColumn(transactions, transactions.categoryId);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Stream<List<Transaction>> get allTransactions {
    return (select(transactions)..orderBy([
          (t) =>
              OrderingTerm(expression: t.occurredTime, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Future<int> addTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }

  Future<int> deleteTransaction(String id) {
    return (delete(transactions)..where((item) => item.id.equals(id))).go();
  }

  Stream<int> get balance {
    final incomeSum = transactions.amountMinor.sum(
      filter: transactions.type.equalsValue(TransactionType.income),
    );
    final expenseSum = transactions.amountMinor.sum(
      filter: transactions.type.equalsValue(TransactionType.expense),
    );
    final query = selectOnly(transactions)..addColumns([incomeSum, expenseSum]);
    return query.watchSingle().map((row) {
      final income = row.read(incomeSum) ?? 0;
      final expense = row.read(expenseSum) ?? 0;
      return income - expense;
    });
  }
}
