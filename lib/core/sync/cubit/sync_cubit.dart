import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:stockflow/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:stockflow/core/connectivity/domain/network_status.dart';
import 'package:stockflow/core/result.dart';
import 'package:stockflow/core/sync/cubit/pending_sync_cubit.dart';
import 'package:stockflow/core/sync/domain/usecases/push_pending_changes_usecase.dart';

part 'sync_state.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Pushes queued changes to the server, and exposes the outcome as state.
///
/// Auto-triggers a push whenever connectivity comes back online, or whenever
/// a new change is queued while already online. [syncNow] triggers the same
/// push on demand; the [SyncState.isManual] flag lets the UI show progress
/// and a result only for user-initiated pushes.
class SyncCubit extends Cubit<SyncState> {
  SyncCubit({
    required ConnectivityCubit connectivityCubit,
    required PendingSyncCubit pendingSyncCubit,
    required PushPendingChangesUseCase pushPendingChangesUseCase,
  }) : _connectivityCubit = connectivityCubit,
       _pushPendingChangesUseCase = pushPendingChangesUseCase,
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
      _push(isManual: false);
    }
  }

  final ConnectivityCubit _connectivityCubit;
  final PushPendingChangesUseCase _pushPendingChangesUseCase;
  late final StreamSubscription<NetworkStatus> _connectivitySubscription;
  late final StreamSubscription<int> _pendingCountSubscription;
  int _lastPendingCount;
  final PendingSyncCubit _pendingSyncCubit;

  void _onConnectivityChanged(NetworkStatus status) {
    if (status == NetworkStatus.online) {
      _push(isManual: false);
    }
  }

  void _onPendingCountChanged(int count) {
    // Only react to the count going up (a new row was queued) -- a drop
    // means something was just dequeued, i.e. a push already happened, so
    // triggering another one here would just be a wasted no-op attempt.
    final increased = count > _lastPendingCount;
    _lastPendingCount = count;
    if (increased && _connectivityCubit.state == NetworkStatus.online) {
      _push(isManual: false);
    }
  }

  Future<void> _push({required bool isManual}) async {
    // A push is already running -- don't stack a second one.
    if (state is SyncInProgress) return;

    final pendingBefore = _pendingSyncCubit.state;
    emit(SyncInProgress(isManual: isManual));

    try {
      final result = await _pushPendingChangesUseCase();
      switch (result) {
        case Success(:final data):
          _logger.i('Sync push: $data change(s) pushed.');
          // pushPending() returns only a count (D5). Infer "all failed":
          // queue was non-empty and nothing left it.
          final allFailed = pendingBefore > 0 && data == 0;
          emit(
            SyncCompleted(
              pushedCount: data,
              allFailed: allFailed,
              isManual: isManual,
            ),
          );
        case Failure(:final message):
          _logger.w('Sync push failed to read the queue: $message');
          emit(SyncFailure(message: message));
      }
    } catch (e) {
      _logger.e('Sync push threw unexpectedly', error: e);
      emit(SyncFailure(message: e.toString()));
    }
  }

  /// Pushes queued changes now, at the user's request. No-op while a push
  /// is already in flight.
  Future<void> syncNow() => _push(isManual: true);

  @override
  Future<void> close() {
    _connectivitySubscription.cancel();
    _pendingCountSubscription.cancel();
    return super.close();
  }
}
