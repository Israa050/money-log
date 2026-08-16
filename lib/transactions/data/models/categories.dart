
import 'package:drift/drift.dart';

class Categories extends Table{
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get colorHex => text().nullable()();
  @override Set<Column> get primaryKey => {id};
}