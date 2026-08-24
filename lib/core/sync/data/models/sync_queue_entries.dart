import 'package:drift/drift.dart';
import 'package:stockflow/core/sync/domain/entities/operation_type.dart';

class SyncQueueEntries extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => textEnum<OperationType>()();
  TextColumn get payload => text()();
  late final createdAt = dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
