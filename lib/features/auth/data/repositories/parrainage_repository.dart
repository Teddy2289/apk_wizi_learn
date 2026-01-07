import 'package:wizi_learn/core/network/api_client.dart';

class ParrainageRepository {
  final ApiClient apiClient;

  ParrainageRepository({required this.apiClient});

  Future<Map<String, dynamic>?> inscrireFilleul({
    required String prenom,
    required String nom,
    required String telephone,
    required String parrainId,
  }) async {
    try {
      final data = {
        'prenom': prenom,
        'nom': nom,
        'telephone': telephone,
        'parrain_id': int.tryParse(parrainId) ?? parrainId,
        'motif': "Soumission d'une demande d'inscription par parrainage",
        'statut': "1", // Statut comme string "1"
        'civilite': 'M', // Optionnel
        'date_inscription': DateTime.now().toIso8601String().split('T')[0], // Optionnel
      };

      // debugPrint("🟡 Payload envoyé: $data");

      final response = await apiClient.post('/parrainage/register-filleul', data: data);

      // debugPrint("🟢 Réponse backend: ${response.statusCode} - ${response.data}");

      if (response.data['success'] == true) {
        return {
          'success': true,
          'message': response.data['message'],
          'data': response.data['data'],
        };
      } else {
        // debugPrint("🔴 Erreurs backend: ${response.data['errors']}"); 
        return {
          'success': false,
          'errors': response.data['errors'],
          'message': response.data['message'] ?? 'Erreur lors de l\'inscription',
        };
      }
    } catch (e) {
      // debugPrint("🔴 Erreur inscription filleul: $e");    
      return {
        'success': false,
        'message': 'Erreur technique: $e',
      };
    }
  }

  void dispose() {
    // Aucune ressource à libérer
  }
}