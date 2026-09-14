import 'package:drift/drift.dart';

// Single key-value table for sync bookkeeping that isn't per-entity, e.g.
// 'lastPulledAt'. One row per key rather than a dedicated column/table per
// value, since this is expected to stay small (a handful of watermarks).
class SyncMeta extends Table {
  TextColumn get key => text()();
  DateTimeColumn get value => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
