import 'package:drift/drift.dart';

enum TransactionType { income, expense }

class Transactions extends Table {
  TextColumn get id => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get type => textEnum<TransactionType>()();
  TextColumn get note => text().nullable()();
  late final occurredTime = dateTime().withDefault(currentDateAndTime)();
  late final creationTime = dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
