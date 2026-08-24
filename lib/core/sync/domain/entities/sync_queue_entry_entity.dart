import 'package:stockflow/core/sync/domain/entities/operation_type.dart';

class SyncQueueEntryEntity {
  final String id;
  final String entityType;
  final String entityId;
  final OperationType operation;
  final String payload;
  final DateTime createdAt;

  SyncQueueEntryEntity({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
  });
}
