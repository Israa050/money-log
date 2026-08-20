import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/core/connectivity/domain/network_status.dart';
import 'package:stockflow/core/connectivity/domain/usecases/watch_connectivity_usecase.dart';

class ConnectivityCubit extends Cubit<NetworkStatus> {
  ConnectivityCubit({
    required WatchConnectivityUseCase watchConnectivityUseCase,
  }) : _subscription = watchConnectivityUseCase().listen(null),
       super(NetworkStatus.online) {
    _subscription.onData(emit);
  }

  final StreamSubscription<NetworkStatus> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
