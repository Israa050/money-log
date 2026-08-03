import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockflow/core/result.dart';
import 'package:stockflow/transactions/data/models/transactions.dart';
import 'package:stockflow/transactions/data/repos/transactions_repository.dart';
import 'package:stockflow/transactions/data/transactions_data_source.dart';
import 'package:uuid/uuid.dart';

void main() {
  late TransactionsDataSource dataSource;
  late TransactionsRepository repository;

  setUp(() {
    dataSource = TransactionsDataSource(NativeDatabase.memory());
    repository = TransactionsRepository(dataSource: dataSource);
  });

  tearDown(() async {
    await dataSource.close();
  });

  group('newTransactionEntry', () {
    test('generates a non-empty id each call, and two calls produce different ids.',()async{
        final entry = repository.newTransactionEntry(amountMinor: 5, type: TransactionType.income);
        final entrytwo = repository.newTransactionEntry(amountMinor: 5, type: TransactionType.income);
        expect(entry.id, isNot(null));
        expect(entry.id, isNot(entrytwo.id));
    });
     test('note omitted -> Value(null) wrapping (not Value.absent()), matches "note not provided" semantics.',()async{
        final entry = repository.newTransactionEntry(amountMinor: 5, type: TransactionType.income);
        expect(entry.note, const Value<String?>(null));
    });

    test('note provided -> Value(note) wrapping, round-trips through addTransaction + getAllTransactions.', () async {
      final entry = repository.newTransactionEntry(
        amountMinor: 5,
        type: TransactionType.income,
        note: 'groceries',
      );

      await repository.addTransaction(entry);
      final result = await repository.getAllTransactions();

      final rows = (result as Success<List<Transaction>>).data;
      expect(rows.single.note, 'groceries');
    });

    test('type and amountMinor are passed straight through unchanged into the companion.', () {
      final entry = repository.newTransactionEntry(
        amountMinor: 999,
        type: TransactionType.expense,
      );

      expect(entry.amountMinor, const Value(999));
      expect(entry.type, const Value(TransactionType.expense));
    });
  });

  group('getAllTransactions', () {
    test('empty table -> Success([]).', () async {
      final result = await repository.getAllTransactions();

      expect(result, isA<Success<List<Transaction>>>());
      expect((result as Success<List<Transaction>>).data, isEmpty);
    });

    test('after inserting via dataSource directly -> Success(list) containing those rows.', () async {
      final entry = repository.newTransactionEntry(amountMinor: 10, type: TransactionType.income);
      await dataSource.addTransaction(entry);

      final result = await repository.getAllTransactions();

      final rows = (result as Success<List<Transaction>>).data;
      expect(rows.single.id, entry.id.value);
    });

    // Not tested here: forcing dataSource to throw. Closing the connection
    // doesn't throw on NativeDatabase.memory() -- it hangs the next query
    // instead, so it can't be used to reliably exercise the catch/Failure
    // path. addTransaction's "duplicate id" test below is the one case with
    // a real, fast way to trigger the underlying exception.
  });

  group('addTransaction', () {
    test('valid entry -> Success(result), and the row is readable via getAllTransactions after.', () async {
      final entry = repository.newTransactionEntry(amountMinor: 20, type: TransactionType.expense);

      final addResult = await repository.addTransaction(entry);
      expect(addResult, isA<Success<int>>());

      final allResult = await repository.getAllTransactions();
      final rows = (allResult as Success<List<Transaction>>).data;
      expect(rows.single.id, entry.id.value);
    });

    test('duplicate id (insert same id twice) -> Failure(message), does NOT throw/propagate.', () async {
      final entry = repository.newTransactionEntry(amountMinor: 20, type: TransactionType.expense);
      await repository.addTransaction(entry);

      final secondResult = await repository.addTransaction(entry);

      expect(secondResult, isA<Failure<int>>());
    });
  });

  group('deleteTransaction', () {
    test('existing id -> Success(1), row no longer present afterward.', () async {
      final entry = repository.newTransactionEntry(amountMinor: 30, type: TransactionType.expense);
      await repository.addTransaction(entry);

      final deleteResult = await repository.deleteTransaction(entry.id.value);

      expect(deleteResult, isA<Success<int>>());
      expect((deleteResult as Success<int>).data, 1);

      final allResult = await repository.getAllTransactions();
      expect((allResult as Success<List<Transaction>>).data, isEmpty);
    });

    test('non-existent id -> Success(0), not a Failure (mirrors data source behavior).', () async {
      final deleteResult = await repository.deleteTransaction(const Uuid().v4());

      expect(deleteResult, isA<Success<int>>());
      expect((deleteResult as Success<int>).data, 0);
    });

    // Not tested here: forcing dataSource to throw, for the same reason as
    // getAllTransactions above (close() hangs rather than throws on this
    // in-memory driver).
  });
}
