import 'package:get_it/get_it.dart';
import 'package:stockflow/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:stockflow/core/connectivity/data/connectivity_repository_impl.dart';
import 'package:stockflow/core/connectivity/domain/connectivity_repository.dart';
import 'package:stockflow/core/connectivity/domain/usecases/watch_connectivity_usecase.dart';
import 'package:stockflow/transactions/bloc/balance_cubit.dart';
import 'package:stockflow/transactions/bloc/categories_bloc.dart';
import 'package:stockflow/transactions/bloc/category_totals_cubit.dart';
import 'package:stockflow/transactions/bloc/transactions_bloc.dart';
import 'package:stockflow/transactions/data/connection.dart';
import 'package:stockflow/transactions/data/repos/category_repository_impl.dart';
import 'package:stockflow/transactions/data/repos/transactions_repository_impl.dart';
import 'package:stockflow/transactions/data/transactions_data_source.dart';
import 'package:stockflow/transactions/domain/repositories/category_repository.dart';
import 'package:stockflow/transactions/domain/repositories/transactions_repository.dart';
import 'package:stockflow/transactions/domain/usecases/add_category_usecase.dart';
import 'package:stockflow/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:stockflow/transactions/domain/usecases/delete_category_usecase.dart';
import 'package:stockflow/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:stockflow/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:stockflow/transactions/domain/usecases/update_category_usecase.dart';
import 'package:stockflow/transactions/domain/usecases/watch_balance_usecase.dart';
import 'package:stockflow/transactions/domain/usecases/watch_categories_usecase.dart';
import 'package:stockflow/transactions/domain/usecases/watch_category_totals_usecase.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<ConnectivityRepository>(
    () => ConnectivityRepositoryImpl(),
  );

  getIt.registerLazySingleton<WatchConnectivityUseCase>(
    () => WatchConnectivityUseCase(getIt<ConnectivityRepository>()),
  );

  getIt.registerLazySingleton<ConnectivityCubit>(
    () => ConnectivityCubit(
      watchConnectivityUseCase: getIt<WatchConnectivityUseCase>(),
    ),
  );

  getIt.registerLazySingleton<TransactionsDataSource>(
    () => TransactionsDataSource(openTransactionsConnection()),
  );

  getIt.registerLazySingleton<TransactionsRepository>(
    () =>
        TransactionsRepositoryImpl(dataSource: getIt<TransactionsDataSource>()),
  );

  getIt.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(dataSource: getIt<TransactionsDataSource>()),
  );

  getIt.registerLazySingleton<GetTransactionsUseCase>(
    () => GetTransactionsUseCase(getIt<TransactionsRepository>()),
  );

  getIt.registerLazySingleton<WatchCategoriesUseCase>(
    () => WatchCategoriesUseCase(getIt<CategoryRepository>()),
  );

  getIt.registerLazySingleton<AddCategoryUseCase>(
    () => AddCategoryUseCase(getIt<CategoryRepository>()),
  );

  getIt.registerLazySingleton<UpdateCategoryUseCase>(
    () => UpdateCategoryUseCase(getIt<CategoryRepository>()),
  );

  getIt.registerLazySingleton<DeleteCategoryUseCase>(
    () => DeleteCategoryUseCase(getIt<CategoryRepository>()),
  );

  getIt.registerLazySingleton<WatchBalanceUseCase>(
    () => WatchBalanceUseCase(getIt<TransactionsRepository>()),
  );

  getIt.registerLazySingleton<WatchCategoryTotalsUsecase>(
    () => WatchCategoryTotalsUsecase(
      categoryRepository: getIt<CategoryRepository>(),
    ),
  );

  getIt.registerLazySingleton<AddTransactionUseCase>(
    () => AddTransactionUseCase(getIt<TransactionsRepository>()),
  );

  getIt.registerLazySingleton<DeleteTransactionUseCase>(
    () => DeleteTransactionUseCase(getIt<TransactionsRepository>()),
  );

  getIt.registerFactory<TransactionsBloc>(
    () => TransactionsBloc(
      getTransactionsUseCase: getIt<GetTransactionsUseCase>(),
      addTransactionUseCase: getIt<AddTransactionUseCase>(),
      deleteTransactionUseCase: getIt<DeleteTransactionUseCase>(),
      watchCategoriesUseCase: getIt<WatchCategoriesUseCase>(),
    ),
  );

  getIt.registerFactory<BalanceCubit>(
    () => BalanceCubit(watchBalanceUseCase: getIt<WatchBalanceUseCase>()),
  );

  getIt.registerFactory<CategoryTotalsCubit>(
    () => CategoryTotalsCubit(
      watchCategoryTotals: getIt<WatchCategoryTotalsUsecase>(),
    ),
  );

  getIt.registerFactory<CategoriesBloc>(
    () => CategoriesBloc(
      watchCategoriesUseCase: getIt<WatchCategoriesUseCase>(),
      addCategoryUseCase: getIt<AddCategoryUseCase>(),
      updateCategoryUseCase: getIt<UpdateCategoryUseCase>(),
      deleteCategoryUseCase: getIt<DeleteCategoryUseCase>(),
    ),
  );
}
