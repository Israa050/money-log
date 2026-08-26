part of 'export_cubit.dart';

@immutable
sealed class ExportState {}

final class ExportIdle extends ExportState {}

final class ExportInProgress extends ExportState {}

final class ExportSuccess extends ExportState {
  final ExportedFile file;

  ExportSuccess({required this.file});
}

final class ExportFailure extends ExportState {
  final String message;

  ExportFailure({required this.message});
}
