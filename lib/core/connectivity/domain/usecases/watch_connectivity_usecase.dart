import 'package:stockflow/core/connectivity/domain/connectivity_repository.dart';
import 'package:stockflow/core/connectivity/domain/network_status.dart';

class WatchConnectivityUseCase {
  WatchConnectivityUseCase(this._repository);

  final ConnectivityRepository _repository;

  Stream<NetworkStatus> call() {
    return _repository.watchConnectivityChanges();
  }
}
