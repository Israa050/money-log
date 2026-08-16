import 'package:drift/drift.dart';
import 'package:stockflow/transactions/data/models/categories.dart';
import 'package:stockflow/transactions/domain/entities/transaction_type.dart';

class Transactions extends Table {
  TextColumn get id => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get type => textEnum<TransactionType>()();
  TextColumn get note => text().nullable()();
  late final occurredTime = dateTime().withDefault(currentDateAndTime)();
  late final creationTime = dateTime().withDefault(currentDateAndTime)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  @override
  Set<Column> get primaryKey => {id};
}
