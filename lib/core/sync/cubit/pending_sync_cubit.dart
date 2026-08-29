import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/core/sync/domain/usecases/watch_pending_sync_count_usecase.dart';

/// Emits the number of rows currently in the sync queue.
///
/// There is no drain process yet, so this count only ever grows -- see
/// docs/sync-queue.md. The UI treats it as "changes recorded on this
/// device", not "sync failures".
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
