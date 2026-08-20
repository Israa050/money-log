import 'package:stockflow/core/connectivity/domain/network_status.dart';
import 'package:stockflow/core/result.dart';

abstract class ConnectivityRepository {
  Future<Result<NetworkStatus>> checkConnectivity();

  Stream<NetworkStatus> watchConnectivityChanges();
}
