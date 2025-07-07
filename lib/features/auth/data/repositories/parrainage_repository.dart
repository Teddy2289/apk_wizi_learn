import 'package:flutter/cupertino.dart';
import 'package:wizi_learn/core/network/api_client.dart';

class ParrainageRepository {
  final ApiClient apiClient;

  ParrainageRepository({required this.apiClient});

  Future<String?> genererLienParrainage() async {
    try {
      final response = await apiClient.post('/parrainage/generate-link');

      if (response.data['success'] == true && response.data['token'] != null) {
        final token = response.data['token'];
        return "https://wizi-learn.com/parrainage/$token";
      }

      return null;
    } catch (e) {
      // print("Erreur lors de la génération du lien : $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getStatsParrainage() async {
    try {
      final response = await apiClient.get('/stagiaire/parrainage/stats');
      debugPrint("Response data: ${response.data}");

      if (response.data['success'] == true) {
        // Retournez directement response.data car les stats sont à la racine
        return {
          'parrain_id': response.data['parrain_id'],
          'nombre_filleuls': response.data['nombre_filleuls'],
          'total_points': response.data['total_points'],
          'gains':response.data['gains'],
        };
        // Ou simplement: return response.data;
      }
      return null;
    } catch (e) {
      debugPrint("Erreur lors de la récupération des stats: $e");
      return null;
    }
  }
}
