import 'package:drift/drift.dart';
import 'package:stockflow/transactions/domain/entities/operation_type.dart';

class SyncQueueEntries extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => textEnum<OperationType>()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
