import 'package:dio/dio.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/media_model.dart';

class MediaRepository {
  final ApiClient apiClient;
  MediaRepository({required this.apiClient});

  Future<List<Media>> getMediasByFormation(String? formationId, {String category = 'tutoriel'}) async {
    if (formationId == null) return [];
    final response = await apiClient.dio.get(
      '/medias',
      queryParameters: {
        'formation_id': formationId,
        'category': category,
      },
    );
    final data = response.data;
    // On suppose que l'API retourne { 'tutoriels': [...], 'astuces': [...] }
    final List mediasJson = (data[category == 'tutoriel' ? 'tutoriels' : 'astuces'] ?? []) as List;
    return mediasJson.map((e) => Media.fromJson(e)).toList();
  }
}
