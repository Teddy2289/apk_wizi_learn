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
}
