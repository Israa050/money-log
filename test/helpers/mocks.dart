import 'package:mocktail/mocktail.dart';
import 'package:stockflow/transactions/domain/repositories/category_repository.dart';
import 'package:stockflow/transactions/domain/repositories/transactions_repository.dart';
import 'package:stockflow/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:stockflow/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:stockflow/transactions/domain/usecases/get_categories_usecase.dart';
import 'package:stockflow/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:stockflow/transactions/domain/usecases/watch_balance_usecase.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockGetTransactionsUseCase extends Mock
    implements GetTransactionsUseCase {}

class MockAddTransactionUseCase extends Mock implements AddTransactionUseCase {}

class MockDeleteTransactionUseCase extends Mock
    implements DeleteTransactionUseCase {}

class MockGetCategoriesUseCase extends Mock implements GetCategoriesUseCase {}

class MockWatchBalanceUseCase extends Mock implements WatchBalanceUseCase {}
