import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

abstract interface class ConnectivityService {
  Stream<NetworkStatus> get changes;
  Future<NetworkStatus> current();
}

class PluginConnectivityService implements ConnectivityService {
  PluginConnectivityService(this.connectivity);

  final Connectivity connectivity;

  @override
  Stream<NetworkStatus> get changes => connectivity.onConnectivityChanged
      .map(
        (results) => _map(results),
      )
      .distinct();

  @override
  Future<NetworkStatus> current() async =>
      _map(await connectivity.checkConnectivity());

  NetworkStatus _map(List<ConnectivityResult> results) {
    if (results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none)) {
      return NetworkStatus.offline;
    }
    return NetworkStatus.online;
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>(
  (_) => PluginConnectivityService(Connectivity()),
);

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.current();
  yield* service.changes;
});
