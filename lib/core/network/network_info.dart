import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// Wraps [Connectivity] + [InternetConnectionChecker] to expose a simple API.
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;
  final InternetConnectionChecker _connectionChecker;

  NetworkInfoImpl({
    required Connectivity connectivity,
    required InternetConnectionChecker connectionChecker,
  }) : _connectivity = connectivity,
       _connectionChecker = connectionChecker;

  @override
  Future<bool> get isConnected => _connectionChecker.hasConnection;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map((result) => [result]);
}
