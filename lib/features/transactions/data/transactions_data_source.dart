import 'package:drift/drift.dart';
import 'package:stockflow/core/sync/data/models/sync_queue_entries.dart';
import 'package:stockflow/core/sync/domain/entities/operation_type.dart';
import 'package:stockflow/features/categories/data/models/categories.dart';
import 'package:stockflow/features/transactions/data/models/transactions.dart';
import 'package:stockflow/features/transactions/domain/entities/transaction_type.dart';

part 'transactions_data_source.g.dart';

// Fixed (not randomly generated) so they're stable and predictable across
// installs -- but real UUIDs, not human-readable strings like the old
// 'default-food', since Supabase's category_id/id columns are typed uuid
// and reject anything else.
const defaultCategoryFoodId = '11111111-1111-1111-1111-111111111111';
const defaultCategoryTransportId = '22222222-2222-2222-2222-222222222222';
const defaultCategoryShoppingId = '33333333-3333-3333-3333-333333333333';
const defaultCategoryBillsId = '44444444-4444-4444-4444-444444444444';

final _defaultCategories = [
  CategoriesCompanion.insert(
    id: defaultCategoryFoodId,
    name: 'Food',
    colorHex: const Value('#FF9800'),
  ),
  CategoriesCompanion.insert(
    id: defaultCategoryTransportId,
    name: 'Transport',
    colorHex: const Value('#2196F3'),
  ),
  CategoriesCompanion.insert(
    id: defaultCategoryShoppingId,
    name: 'Shopping',
    colorHex: const Value('#9C27B0'),
  ),
  CategoriesCompanion.insert(
    id: defaultCategoryBillsId,
    name: 'Bills',
    colorHex: const Value('#F44336'),
  ),
];

@DriftDatabase(tables: [Transactions, Categories, SyncQueueEntries])
class TransactionsDataSource extends _$TransactionsDataSource {
  TransactionsDataSource(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await batch((b) => b.insertAll(categories, _defaultCategories));
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(categories);
        await m.addColumn(transactions, transactions.categoryId);
      }
      if (from < 3) {
        await m.alterTable(TableMigration(transactions));
      }
      if (from < 4) {
        await m.createTable(syncQueueEntries);
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

  // One-shot read (vs. the .watch() stream above) -- used by the export/backup
  // feature, which needs a single snapshot rather than a live subscription.
  Future<List<Transaction>> getAllTransactionsOnce() {
    return (select(transactions)..orderBy([
          (t) =>
              OrderingTerm(expression: t.occurredTime, mode: OrderingMode.desc),
        ]))
        .get();
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

  Stream<List<Category>> get watchAllCategories {
    return select(categories).watch();
  }

  // One-shot read (vs. the .watch() stream above) -- used by the export/backup
  // feature, which needs a single snapshot rather than a live subscription.
  Future<List<Category>> getAllCategoriesOnce() {
    return select(categories).get();
  }

  Future<int> addCategory(CategoriesCompanion entry) {
    return into(categories).insert(entry);
  }

  Future<int> deleteCategory(String id) {
    return (delete(categories)..where((item) => item.id.equals(id))).go();
  }

  Future<bool> updateCategory(CategoriesCompanion entry) {
    return update(categories).replace(entry);
  }

  Future<Category?> findCategoryByName(String name) {
    // .equals() is case-sensitive (SQLite's default BINARY collation), but
    // duplicate-name checks in the repository are meant to be
    // case-insensitive, so compare lowercased on both sides.
    return (select(categories)
          ..where((c) => c.name.lower().equals(name.toLowerCase())))
        .getSingleOrNull();
  }

  Stream<List<CategoryTotalRow>> get categoryTotals {
    final expenseSum = transactions.amountMinor.sum();

    final query = selectOnly(transactions)
      ..addColumns([
        categories.id,
        categories.name,
        categories.colorHex,
        expenseSum,
      ])
      ..join([
        leftOuterJoin(
          categories,
          categories.id.equalsExp(transactions.categoryId),
        ),
      ])
      ..where(transactions.type.equalsValue(TransactionType.expense))
      ..groupBy([transactions.categoryId]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => CategoryTotalRow(
              categoryId: row.read(categories.id),
              categoryName: row.read(categories.name),
              colorHex: row.read(categories.colorHex),
              totalMinor: row.read(expenseSum) ?? 0,
            ),
          )
          .toList(),
    );
  }

  Future<int> addSyncQueueEntry(SyncQueueEntriesCompanion entry) {
    return into(syncQueueEntries).insert(entry);
  }

  Stream<int> get pendingSyncCount {
    final count = countAll();
    final query = selectOnly(syncQueueEntries)..addColumns([count]);
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<List<SyncQueueEntry>> getAllSyncQueueEntries() {
    return select(syncQueueEntries).get();
  }

  Future<int> deleteSyncQueueEntry(String id) {
    return (delete(syncQueueEntries)..where((item) => item.id.equals(id))).go();
  }
}

class CategoryTotalRow {
  CategoryTotalRow({
    required this.categoryId,
    required this.categoryName,
    required this.colorHex,
    required this.totalMinor,
  });

  final String? categoryId;
  final String? categoryName;
  final String? colorHex;
  final int totalMinor;
}
