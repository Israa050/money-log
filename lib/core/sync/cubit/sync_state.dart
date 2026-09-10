part of 'sync_cubit.dart';

@immutable
sealed class SyncState {}

/// No push has been attempted this session.
final class SyncIdle extends SyncState {}

/// A push is running. [isManual] is true only for [SyncCubit.syncNow].
final class SyncInProgress extends SyncState {
  SyncInProgress({required this.isManual});

  final bool isManual;
}

/// A push finished -- not necessarily successfully. [pushPending] returns a
/// count even when every row failed, so [allFailed] is inferred, not proven.
final class SyncCompleted extends SyncState {
  SyncCompleted({
    required this.pushedCount,
    required this.allFailed,
    required this.isManual,
  });

  final int pushedCount;
  final bool allFailed;
  final bool isManual;
}

/// The queue could not be read, or the push threw.
final class SyncFailure extends SyncState {
  SyncFailure({required this.message});

  final String message;
}
