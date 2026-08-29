import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/core/sync/cubit/pending_sync_cubit.dart';

/// App-bar action showing how many local changes are waiting to sync.
///
/// Renders nothing when the count is zero. The count only grows for now
/// (no drain process -- see docs/sync-queue.md), so the copy says
/// "waiting to sync", never "failed".
class PendingSyncBadge extends StatelessWidget {
  const PendingSyncBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PendingSyncCubit, int>(
      builder: (context, count) {
        if (count == 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: Tooltip(
              message: count == 1
                  ? '1 change waiting to sync'
                  : '$count changes waiting to sync',
              child: Badge(
                label: Text('$count'),
                child: const Icon(Icons.cloud_upload_outlined),
              ),
            ),
          ),
        );
      },
    );
  }
}
