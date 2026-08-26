import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/features/backup/domain/entities/exported_file.dart';
import 'package:stockflow/features/backup/domain/usecases/export_data_usecase.dart';

part 'export_state.dart';

class ExportCubit extends Cubit<ExportState> {
  ExportCubit({required this.exportDataUseCase}) : super(ExportIdle());
  final ExportDataUseCase exportDataUseCase;

  Future<void> export() async {
    if (state is ExportInProgress) return;

    emit(ExportInProgress());

    final result = await exportDataUseCase();

    result.when(
      success: (exportedFile) {
        emit(ExportSuccess(file: exportedFile));
      },
      failure: (message) {
        emit(ExportFailure(message: message));
      },
    );
  }
}
