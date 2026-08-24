import 'package:stockflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:stockflow/features/transactions/domain/repositories/transactions_repository.dart';

class GetTransactionsUseCase {
  GetTransactionsUseCase(this._repository);

  final TransactionsRepository _repository;

  Stream<List<TransactionEntity>> call() {
    return _repository.getAllTransactions();
  }
}
