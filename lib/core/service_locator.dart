import 'package:get_it/get_it.dart';
import 'package:stockflow/transactions/bloc/transactions_bloc.dart';
import 'package:stockflow/transactions/data/connection.dart';
import 'package:stockflow/transactions/data/repos/transactions_repository.dart';
import 'package:stockflow/transactions/data/transactions_data_source.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<TransactionsDataSource>(
    () => TransactionsDataSource(openTransactionsConnection()),
  );

  getIt.registerLazySingleton<TransactionsRepository>(
    () => TransactionsRepository(dataSource: getIt<TransactionsDataSource>()),
  );

  getIt.registerFactory<TransactionsBloc>(
    () => TransactionsBloc(transactionsRepository: getIt<TransactionsRepository>()),
  );
}
