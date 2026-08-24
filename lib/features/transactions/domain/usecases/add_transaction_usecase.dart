import 'package:stockflow/core/result.dart';
import 'package:stockflow/features/transactions/domain/entities/transaction_type.dart';
import 'package:stockflow/features/transactions/domain/repositories/transactions_repository.dart';

class AddTransactionUseCase {
  AddTransactionUseCase(this._repository);

  final TransactionsRepository _repository;

  Future<Result<void>> call({
    required int amountMinor,
    required TransactionType type,
    String? note,
    String? categoryId,
  }) {
    return _repository.addTransaction(
      amountMinor: amountMinor,
      type: type,
      note: note,
      categoryId: categoryId,
    );
  }
}
