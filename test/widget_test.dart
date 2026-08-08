import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockflow/core/service_locator.dart';
import 'package:stockflow/main.dart';
import 'package:stockflow/transactions/bloc/transactions_bloc.dart';
import 'package:stockflow/transactions/data/repos/transactions_repository.dart';
import 'package:stockflow/transactions/data/transactions_data_source.dart';
import 'package:stockflow/transactions/presentation/screens/transactions_screen.dart';

void main() {
  testWidgets('App boots without throwing', (WidgetTester tester) async {
    // Registers against an in-memory Drift database instead of
    // setupServiceLocator()'s real disk-backed connection, so this test
    // doesn't touch path_provider/disk I/O and every resource can be
    // closed deterministically in tearDown below.
    final dataSource = TransactionsDataSource(NativeDatabase.memory());
    getIt.registerSingleton<TransactionsDataSource>(dataSource);
    getIt.registerSingleton<TransactionsRepository>(
      TransactionsRepository(dataSource: dataSource),
    );
    getIt.registerFactory<TransactionsBloc>(
      () => TransactionsBloc(
        transactionsRepository: getIt<TransactionsRepository>(),
      ),
    );

    addTearDown(() async {
      await getIt.reset();
      await dataSource.close();
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(TransactionsScreen), findsOneWidget);

    // Let the bloc's watch() subscription deliver its first Loaded state.
    await tester.pump();

    // Replace the widget tree with an empty one so BlocProvider disposes
    // the TransactionsBloc, which calls _subscription.cancel(). Drift's
    // stream teardown (StreamQueryStore.markAsClosed) schedules its own
    // zero-duration Timer to finish closing the query -- flutter_test runs
    // the whole body inside a fake_async zone, so that timer is virtual and
    // only fires once the fake clock is advanced past it. pump() with an
    // explicit non-zero duration elapses the fake clock and lets it fire;
    // a bare pump() (zero elapsed time) does not.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
