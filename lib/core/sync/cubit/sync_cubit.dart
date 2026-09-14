import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:stockflow/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:stockflow/core/connectivity/domain/network_status.dart';
import 'package:stockflow/core/result.dart';
import 'package:stockflow/core/sync/cubit/pending_sync_cubit.dart';
import 'package:stockflow/core/sync/domain/usecases/pull_remote_changes_usecase.dart';
import 'package:stockflow/core/sync/domain/usecases/push_pending_changes_usecase.dart';

part 'sync_state.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Pushes queued changes to the server, then pulls remote changes down, and
/// exposes the outcome as state.
///
/// Auto-triggers on the same events for both directions: connectivity
/// coming back online, or a new change queued while already online.
/// [syncNow] triggers the same push-then-pull on demand; the
/// [SyncState.isManual] flag lets the UI show progress and a result only
/// for user-initiated syncs.
class SyncCubit extends Cubit<SyncState> {
  SyncCubit({
    required ConnectivityCubit connectivityCubit,
    required PendingSyncCubit pendingSyncCubit,
    required PushPendingChangesUseCase pushPendingChangesUseCase,
    required PullRemoteChangesUseCase pullRemoteChangesUseCase,
  }) : _connectivityCubit = connectivityCubit,
       _pushPendingChangesUseCase = pushPendingChangesUseCase,
       _pullRemoteChangesUseCase = pullRemoteChangesUseCase,
       _lastPendingCount = pendingSyncCubit.state,
       _pendingSyncCubit = pendingSyncCubit,
       super(SyncIdle()) {
    _connectivitySubscription = connectivityCubit.stream.listen(
      _onConnectivityChanged,
    );
    _pendingCountSubscription = pendingSyncCubit.stream.listen(
      _onPendingCountChanged,
    );
    if (connectivityCubit.state == NetworkStatus.online) {
      _sync(isManual: false);
    }
  }

  final ConnectivityCubit _connectivityCubit;
  final PushPendingChangesUseCase _pushPendingChangesUseCase;
  final PullRemoteChangesUseCase _pullRemoteChangesUseCase;
  late final StreamSubscription<NetworkStatus> _connectivitySubscription;
  late final StreamSubscription<int> _pendingCountSubscription;
  int _lastPendingCount;
  final PendingSyncCubit _pendingSyncCubit;

  void _onConnectivityChanged(NetworkStatus status) {
    if (status == NetworkStatus.online) {
      _sync(isManual: false);
    }
  }

  void _onPendingCountChanged(int count) {
    // Only react to the count going up (a new row was queued) -- a drop
    // means something was just dequeued, i.e. a push already happened, so
    // triggering another one here would just be a wasted no-op attempt.
    final increased = count > _lastPendingCount;
    _lastPendingCount = count;
    if (increased && _connectivityCubit.state == NetworkStatus.online) {
      _sync(isManual: false);
    }
  }

  Future<void> _sync({required bool isManual}) async {
    // A sync is already running -- don't stack a second one.
    if (state is SyncInProgress) return;

    final pendingBefore = _pendingSyncCubit.state;
    emit(SyncInProgress(isManual: isManual));

    try {
      final pushResult = await _pushPendingChangesUseCase();
      final pushedCount = switch (pushResult) {
        Success(:final data) => data,
        Failure(:final message) => throw Exception(message),
      };
      _logger.i('Sync push: $pushedCount change(s) pushed.');

      // Pull always runs after push, even when nothing was pending to push:
      // it is the only way this device learns about changes made on other
      // devices signed into the same account. The watermark keeps an
      // empty pull cheap (one small query per entity type).
      final pullResult = await _pullRemoteChangesUseCase();
      final pulledCount = switch (pullResult) {
        Success(:final data) => data,
        Failure(:final message) => throw Exception(message),
      };
      _logger.i('Sync pull: $pulledCount change(s) applied.');

      // pushPending() returns only a count (D5). Infer "all failed": queue
      // was non-empty and nothing left it.
      final allFailed = pendingBefore > 0 && pushedCount == 0;
      emit(
        SyncCompleted(
          pushedCount: pushedCount,
          pulledCount: pulledCount,
          allFailed: allFailed,
          isManual: isManual,
        ),
      );
    } catch (e) {
      _logger.e('Sync failed', error: e);
      emit(SyncFailure(message: e.toString()));
    }
  }

  /// Pushes queued changes and pulls remote changes now, at the user's
  /// request. No-op while a sync is already in flight.
  Future<void> syncNow() => _sync(isManual: true);

  @override
  Future<void> close() {
    _connectivitySubscription.cancel();
    _pendingCountSubscription.cancel();
    return super.close();
  }
}
