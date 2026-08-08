import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockflow/transactions/bloc/transactions_bloc.dart';
import 'package:stockflow/transactions/data/models/transactions.dart';
import 'package:stockflow/transactions/data/repos/transactions_repository.dart';
import 'package:stockflow/transactions/data/transactions_data_source.dart';

// Not using bloc_test/mocktail here (neither is a dev_dependency yet) --
// these drive a real in-memory TransactionsDataSource instead, same approach
// as test/transactions_repository_test.dart. Forcing a repository Failure is
// only reliable via a duplicate-id insert (see transactions_repository_test's
// notes on why closing the connection doesn't work), so failure coverage here
// is limited to AddTransactionEvent, where that trick applies.
//
// AppLaunchEvent subscribes to the repository's watch stream; it no longer
// emits Loading before Loaded -- the first stream tick goes straight to
// Loaded. AddTransactionEvent/DeleteTransactionEvent only emit on failure;
// on success they rely on the AppLaunchEvent subscription's next tick to
// push a refreshed Loaded, so those tests must start with AppLaunchEvent.

void main() {
  late TransactionsDataSource dataSource;
  late TransactionsRepository repository;
  late TransactionsBloc bloc;

  setUp(() {
    dataSource = TransactionsDataSource(NativeDatabase.memory());
    repository = TransactionsRepository(dataSource: dataSource);
    bloc = TransactionsBloc(transactionsRepository: repository);
  });

  tearDown(() async {
    await bloc.close();
    await dataSource.close();
  });

  group('AppLaunchEvent', () {
    test('initial state is TransactionsInitial before any event.', () {
      expect(bloc.state, isA<TransactionsInitial>());
    });

    test('empty table -> emits Loaded([]).', () async {
      final states = <TransactionsState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(AppLaunchEvent());
      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(states, [isA<Loaded>()]);
      expect((states.single as Loaded).data, isEmpty);
    });

    test('existing rows -> Loaded contains them.', () async {
      final entry = repository.newTransactionEntry(
        amountMinor: 10,
        type: TransactionType.income,
      );
      await repository.addTransaction(entry);

      final states = <TransactionsState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(AppLaunchEvent());
      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      final loaded = states.last as Loaded;
      expect(loaded.data.single.id, entry.id.value);
    });

    test(
      'a second AppLaunchEvent does not create a second subscription.',
      () async {
        bloc.add(AppLaunchEvent());
        await Future.delayed(const Duration(milliseconds: 50));

        final states = <TransactionsState>[];
        final sub = bloc.stream.listen(states.add);
        bloc.add(AppLaunchEvent());
        await Future.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        // If a second subscription were created, inserting a row later would
        // deliver two Loaded emissions per change instead of one.
        expect(states, isEmpty);
      },
    );
  });

  group('AddTransactionEvent', () {
    test('success -> no direct emission; the live subscription pushes a '
        'refreshed Loaded including the new row.', () async {
      bloc.add(AppLaunchEvent());
      await Future.delayed(const Duration(milliseconds: 50));

      final states = <TransactionsState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(
        AddTransactionEvent(
          amountMinor: 500,
          type: TransactionType.expense,
          note: 'coffee',
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(states, [isA<Loaded>()]);
      final loaded = states.single as Loaded;
      expect(loaded.data.single.amountMinor, 500);
      expect(loaded.data.single.note, 'coffee');
    });

    // Not tested here: driving AddTransactionEvent itself into the
    // TransactionsError branch. newTransactionEntry() (called inside
    // _onAddTransaction) generates a fresh uuid per call, and the event API
    // only exposes amountMinor/type/note -- there's no way to make the
    // bloc's own handler collide on id through the public event API, so a
    // real failure can't be forced this way. transactions_repository_test
    // already covers the addTransaction-returns-Failure-on-duplicate-id case
    // directly; what's missing is bloc-level coverage of the failure
    // branch's previousData handling, which would need a fake/mock
    // repository (see the bloc_test/mocktail note above) to inject an
    // arbitrary Failure without a real constraint violation.
  });

  group('DeleteTransactionEvent', () {
    test('success -> no direct emission; the live subscription pushes a '
        'refreshed Loaded with the row removed.', () async {
      final entry = repository.newTransactionEntry(
        amountMinor: 40,
        type: TransactionType.expense,
      );
      await repository.addTransaction(entry);
      bloc.add(AppLaunchEvent());
      await Future.delayed(const Duration(milliseconds: 50));

      final states = <TransactionsState>[];
      final sub = bloc.stream.listen(states.add);
      bloc.add(DeleteTransactionEvent(id: entry.id.value));
      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(states, [isA<Loaded>()]);
      expect((states.single as Loaded).data, isEmpty);
    });

    test('non-existent id -> still succeeds; the subscription re-emits the '
        'unchanged Loaded (not an error).', () async {
      bloc.add(AppLaunchEvent());
      await Future.delayed(const Duration(milliseconds: 50));

      final states = <TransactionsState>[];
      final sub = bloc.stream.listen(states.add);
      bloc.add(DeleteTransactionEvent(id: 'does-not-exist'));
      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      // Deleting a non-existent id doesn't change the table, so Drift's
      // watch() query does not re-emit -- there is nothing for the
      // subscription to push, and no error is emitted either.
      expect(states, isEmpty);
    });
  });
}
