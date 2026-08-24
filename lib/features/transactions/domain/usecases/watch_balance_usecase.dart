import 'package:stockflow/features/transactions/domain/repositories/transactions_repository.dart';

class WatchBalanceUseCase {
  WatchBalanceUseCase(this._repository);

  final TransactionsRepository _repository;

  Stream<int> call() {
    return _repository.watchBalance();
  }
}
