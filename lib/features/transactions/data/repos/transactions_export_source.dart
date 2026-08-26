import 'package:stockflow/features/backup/domain/entities/exportable_source.dart';
import 'package:stockflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:stockflow/features/transactions/domain/repositories/transactions_repository.dart';

class TransactionsExportSource extends ExportableSource {
  final TransactionsRepository transactionsRepository;

  TransactionsExportSource({required this.transactionsRepository});

  @override
  String get key => 'transactions';

  @override
  Future<List<Map<String, Object?>>> exportRows() async {
    final transactions = await transactionsRepository.getAllTransactionsOnce();
    return transactions.map(_toMap).toList();
  }

  Map<String, Object?> _toMap(TransactionEntity t) {
    return {
      'id': t.id,
      'amountMinor': t.amountMinor,
      'type': t.type.name,
      'note': t.note,
      'occurredTime': t.timestamp.toUtc().toIso8601String(),
      'categoryId': t.categoryId,
    };
  }
}
