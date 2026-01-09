import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service pour gérer l'état de la connectivité réseau
/// Permet de détecter si l'app est en ligne ou hors ligne
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  /// Stream qui émet true quand connecté, false sinon
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  ConnectivityService() {
    _init();
  }

  void _init() {
    // Écouter les changements de connectivité
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isConnected = results.any((result) => 
        result != ConnectivityResult.none
      );
      _connectivityController.add(isConnected);
    });

    // Vérifier l'état initial
    checkConnectivity();
  }

  /// Vérifie si l'appareil est connecté à internet
  Future<bool> get isConnected async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  /// Vérifie la connectivité et notifie les listeners
  Future<void> checkConnectivity() async {
    final connected = await isConnected;
    _connectivityController.add(connected);
  }

  void dispose() {
    _connectivityController.close();
  }
}
