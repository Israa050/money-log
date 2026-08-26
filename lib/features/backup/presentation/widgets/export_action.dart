import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stockflow/core/service_locator.dart';
import 'package:stockflow/features/backup/cubit/export_cubit.dart';

/// App bar action that exports all transactions and categories to a JSON
/// file and opens the OS share sheet. Wraps its own [ExportCubit] scope so
/// it can be dropped into any app bar without the host screen needing to
/// know about the export feature.
class ExportAction extends StatelessWidget {
  const ExportAction({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ExportCubit>(),
      child: const _ExportActionButton(),
    );
  }
}

class _ExportActionButton extends StatelessWidget {
  const _ExportActionButton();

  void _handleSuccess(BuildContext context, ExportSuccess state) {
    final file = state.file;
    final counts = file.countsByKey.entries
        .map((e) => '${e.value} ${e.key}')
        .join(', ');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Exported $counts')));

    final box = context.findRenderObject() as RenderBox?;
    SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExportCubit, ExportState>(
      listener: (context, state) {
        if (state is ExportSuccess) {
          _handleSuccess(context, state);
        } else if (state is ExportFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final inProgress = state is ExportInProgress;

        return IconButton(
          icon: inProgress
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.ios_share),
          tooltip: 'Export data',
          onPressed: inProgress
              ? null
              : () {}, //context.read<ExportCubit>().export(),
        );
      },
    );
  }
}
