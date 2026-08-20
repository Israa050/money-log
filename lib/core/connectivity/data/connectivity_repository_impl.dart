import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stockflow/core/connectivity/domain/connectivity_repository.dart';
import 'package:stockflow/core/connectivity/domain/network_status.dart';
import 'package:stockflow/core/result.dart';

class ConnectivityRepositoryImpl extends ConnectivityRepository {
  ConnectivityRepositoryImpl({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  NetworkStatus _toNetworkStatus(List<ConnectivityResult> results) {
    final isOffline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    return isOffline ? NetworkStatus.offline : NetworkStatus.online;
  }

  @override
  Future<Result<NetworkStatus>> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return Success(_toNetworkStatus(result));
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Stream<NetworkStatus> watchConnectivityChanges() {
    return _connectivity.onConnectivityChanged.map(_toNetworkStatus);
  }
}
