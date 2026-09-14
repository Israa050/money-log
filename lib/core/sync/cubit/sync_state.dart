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

/// A push-then-pull finished -- not necessarily successfully. [pushPending]
/// returns a count even when every row failed, so [allFailed] is inferred
/// from that count, not proven; it does not reflect the pull.
final class SyncCompleted extends SyncState {
  SyncCompleted({
    required this.pushedCount,
    required this.pulledCount,
    required this.allFailed,
    required this.isManual,
  });

  final int pushedCount;
  final int pulledCount;
  final bool allFailed;
  final bool isManual;
}

/// The queue could not be read, or the push threw.
final class SyncFailure extends SyncState {
  SyncFailure({required this.message});

  final String message;
}
