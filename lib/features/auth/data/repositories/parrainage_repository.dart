import 'package:flutter/cupertino.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'dart:async';

class ParrainageRepository {
  final ApiClient apiClient;
  final StreamController<Map<String, dynamic>> _statsStreamController =
  StreamController<Map<String, dynamic>>.broadcast();
  Timer? _refreshTimer;

  ParrainageRepository({required this.apiClient});

  Future<String?> genererLienParrainage() async {
    try {
      final response = await apiClient.post('/parrainage/generate-link');
      if (response.data['success'] == true && response.data['token'] != null) {
        return "https://wizi-learn.com/parrainage/${response.data['token']}";
      }
      return null;
    } catch (e) {
      debugPrint("Erreur génération lien: $e");
      return null;
    }
  }

  // Stream pour les mises à jour en temps réel
  Stream<Map<String, dynamic>> getLiveStats() {
    // Démarrer le timer si pas déjà fait (rafraîchissement toutes les 5 secondes)
    _refreshTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchAndUpdateStats();
    });

    // Récupérer les stats immédiatement
    _fetchAndUpdateStats();

    return _statsStreamController.stream;
  }

  Future<void> _fetchAndUpdateStats() async {
    try {
      final stats = await getStatsParrainage();
      if (stats != null) {
        _statsStreamController.add(stats);
      }
    } catch (e) {
      debugPrint('Erreur récupération stats: $e');
    }
  }

  Future<Map<String, dynamic>?> getStatsParrainage() async {
    try {
      final response = await apiClient.get('/stagiaire/parrainage/stats');
      if (response.data['success'] == true) {
        return {
          'parrain_id': response.data['parrain_id'],
          'nombre_filleuls': response.data['nombre_filleuls'],
          'total_points': response.data['total_points'],
          'gains': response.data['gains'],
        };
      }
      return null;
    } catch (e) {
      debugPrint("Erreur getStatsParrainage: $e");
      return null;
    }
  }

  // Pour forcer un rafraîchissement manuel
  void forceRefreshStats() {
    _fetchAndUpdateStats();
  }

  // N'oubliez pas de libérer les ressources
  void dispose() {
    _refreshTimer?.cancel();
    _statsStreamController.close();
  }
}