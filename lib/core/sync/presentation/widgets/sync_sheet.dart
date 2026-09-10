import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:stockflow/core/sync/cubit/pending_sync_cubit.dart';
import 'package:stockflow/core/sync/cubit/sync_cubit.dart';
import 'package:stockflow/core/sync/presentation/widgets/sync_now_button.dart';
import 'package:stockflow/core/theme/app_colors.dart';

/// Bottom sheet showing how many changes are waiting to sync and a manual
/// "Sync now" trigger. Opened from [PendingSyncBadge].
Future<void> showSyncSheet(BuildContext context) {
  final syncCubit = context.read<SyncCubit>();
  final pendingSyncCubit = context.read<PendingSyncCubit>();
  final connectivityCubit = context.read<ConnectivityCubit>();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: syncCubit),
        BlocProvider.value(value: pendingSyncCubit),
        BlocProvider.value(value: connectivityCubit),
      ],
      child: const SyncSheet(),
    ),
  );
}

class SyncSheet extends StatelessWidget {
  const SyncSheet({super.key});

  void _onSyncState(BuildContext context, SyncState state) {
    final String text;
    switch (state) {
      case SyncCompleted(:final isManual, :final allFailed, :final pushedCount)
          when isManual:
        if (allFailed) {
          text = "Couldn't send your changes — they're saved on this device.";
        } else if (pushedCount > 0) {
          text =
              'Synced $pushedCount '
              '${pushedCount == 1 ? 'change' : 'changes'}.';
        } else {
          text = 'Already up to date.';
        }
      case SyncFailure(:final message):
        text = message;
      case _:
        return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<SyncCubit, SyncState>(
      listener: _onSyncState,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Sync', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              BlocBuilder<PendingSyncCubit, int>(
                builder: (context, count) {
                  final text = count == 0
                      ? 'No changes waiting to sync'
                      : '$count ${count == 1 ? 'change' : 'changes'} '
                            'waiting to sync';
                  return Text(
                    text,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.inkSoft,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const SyncNowButton(),
              const SizedBox(height: 16),
              Text(
                'Your changes are saved to the cloud. Syncing changes from '
                'other devices is coming later.',
                style: textTheme.bodySmall?.copyWith(color: colors.inkFaint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
