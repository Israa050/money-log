import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:stockflow/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:stockflow/core/connectivity/domain/network_status.dart';
import 'package:stockflow/core/result.dart';
import 'package:stockflow/core/sync/cubit/pending_sync_cubit.dart';
import 'package:stockflow/core/sync/domain/usecases/push_pending_changes_usecase.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Pushes queued changes to the server whenever connectivity comes back
/// online, or whenever a new change is queued while already online. Has no
/// state of its own -- it only exists to own these listeners.
class SyncCubit extends Cubit<void> {
  SyncCubit({
    required ConnectivityCubit connectivityCubit,
    required PendingSyncCubit pendingSyncCubit,
    required PushPendingChangesUseCase pushPendingChangesUseCase,
  }) : _connectivityCubit = connectivityCubit,
       _pushPendingChangesUseCase = pushPendingChangesUseCase,
       _lastPendingCount = pendingSyncCubit.state,
       super(null) {
    _connectivitySubscription = connectivityCubit.stream.listen(
      _onConnectivityChanged,
    );
    _pendingCountSubscription = pendingSyncCubit.stream.listen(
      _onPendingCountChanged,
    );
    if (connectivityCubit.state == NetworkStatus.online) {
      _push();
    }
  }

  final ConnectivityCubit _connectivityCubit;
  final PushPendingChangesUseCase _pushPendingChangesUseCase;
  late final StreamSubscription<NetworkStatus> _connectivitySubscription;
  late final StreamSubscription<int> _pendingCountSubscription;
  int _lastPendingCount;

  void _onConnectivityChanged(NetworkStatus status) {
    if (status == NetworkStatus.online) {
      _push();
    }
  }

  void _onPendingCountChanged(int count) {
    // Only react to the count going up (a new row was queued) -- a drop
    // means something was just dequeued, i.e. a push already happened, so
    // triggering another one here would just be a wasted no-op attempt.
    final increased = count > _lastPendingCount;
    _lastPendingCount = count;
    if (increased && _connectivityCubit.state == NetworkStatus.online) {
      _push();
    }
  }

  Future<void> _push() async {
    try {
      final result = await _pushPendingChangesUseCase();
      switch (result) {
        case Success(:final data):
          _logger.i('Sync push: $data change(s) pushed.');
        case Failure(:final message):
          _logger.w('Sync push failed to read the queue: $message');
      }
    } catch (e) {
      _logger.e('Sync push threw unexpectedly', error: e);
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription.cancel();
    _pendingCountSubscription.cancel();
    return super.close();
  }
}
