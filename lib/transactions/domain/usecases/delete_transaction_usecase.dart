import 'package:stockflow/core/result.dart';
import 'package:stockflow/transactions/domain/repositories/transactions_repository.dart';

class DeleteTransactionUseCase {
  DeleteTransactionUseCase(this._repository);

  final TransactionsRepository _repository;

  Future<Result<int>> call(String id) {
    return _repository.deleteTransaction(id);
  }
}
