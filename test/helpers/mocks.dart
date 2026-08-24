import 'package:mocktail/mocktail.dart';
import 'package:stockflow/features/categories/domain/repositories/category_repository.dart';
import 'package:stockflow/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:stockflow/features/categories/domain/usecases/add_category_usecase.dart';
import 'package:stockflow/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:stockflow/features/categories/domain/usecases/delete_category_usecase.dart';
import 'package:stockflow/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:stockflow/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:stockflow/features/categories/domain/usecases/update_category_usecase.dart';
import 'package:stockflow/features/transactions/domain/usecases/watch_balance_usecase.dart';
import 'package:stockflow/features/categories/domain/usecases/watch_categories_usecase.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockGetTransactionsUseCase extends Mock
    implements GetTransactionsUseCase {}

class MockAddTransactionUseCase extends Mock implements AddTransactionUseCase {}

class MockDeleteTransactionUseCase extends Mock
    implements DeleteTransactionUseCase {}

class MockWatchCategoriesUseCase extends Mock
    implements WatchCategoriesUseCase {}

class MockAddCategoryUseCase extends Mock implements AddCategoryUseCase {}

class MockUpdateCategoryUseCase extends Mock implements UpdateCategoryUseCase {}

class MockDeleteCategoryUseCase extends Mock implements DeleteCategoryUseCase {}

class MockWatchBalanceUseCase extends Mock implements WatchBalanceUseCase {}
