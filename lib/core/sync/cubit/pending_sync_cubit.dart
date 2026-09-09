import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/core/sync/domain/usecases/watch_pending_sync_count_usecase.dart';

/// Emits the number of rows currently in the sync queue.
///
/// SyncCubit drains this queue when connectivity comes back online, so the
/// count drops as pushes succeed. The UI treats it as "changes not yet
/// confirmed on the server", not "sync failures" -- a failed push just
/// leaves its row counted here until the next retry.
class PendingSyncCubit extends Cubit<int> {
  PendingSyncCubit({
    required WatchPendingSyncCountUseCase watchPendingSyncCount,
  }) : _subscription = watchPendingSyncCount().listen(null),
       super(0) {
    _subscription.onData(emit);
  }

  final StreamSubscription<int> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
