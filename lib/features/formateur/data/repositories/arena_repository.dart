import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/arena_model.dart';

class ArenaRepository {
  final ApiClient apiClient;

  ArenaRepository({required this.apiClient});

  Future<List<ArenaFormateur>> getArenaRanking({
    String period = 'all',
    String? formationId,
  }) async {
    try {
      final queryParams = {
        'period': period,
        if (formationId != null && formationId != 'all') 'formation_id': formationId,
      };

      final response = await apiClient.get(
        '/formateur/classement/arena',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ArenaFormateur.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load arena ranking');
      }
    } catch (e) {
      rethrow;
    }
  }
}
