import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/repo/user_repository.dart';

class SyncService {
  final UserRepository repo;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  SyncService(this.repo);

  /// Llamar al arrancar la app
  Future<void> start() async {
    // 1) intenta una synchronización al inicio
    await _trySync();

    // 2) escucha cambios de conectividad y sincroniza cuando haya red
    _sub = Connectivity().onConnectivityChanged.listen((results) async {
      final hasNet = results.any(
        (r) => r == ConnectivityResult.mobile || r == ConnectivityResult.wifi,
      );
      if (hasNet) {
        await _trySync();
      }
    });
  }

  Future<void> _trySync() async {
    try {
      await repo.syncPending();
    } catch (_) {
      // silencia: volverá a intentar cuando haya otra señal
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
  }
}
