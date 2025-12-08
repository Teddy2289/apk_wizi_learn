import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/formation_ranking_model.dart';

class FormationRankingRepository {
  final ApiClient apiClient;

  FormationRankingRepository({required this.apiClient});

  /// Obtenir le classement complet d'une formation
  Future<FormationRanking> getFormationRanking(int formationId) async {
    try {
      final response = await apiClient.dio.get('/formations/$formationId/classement');
      return FormationRanking.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du classement: $e');
    }
  }

  /// Obtenir le rang de l'utilisateur connecté dans une formation
  Future<UserFormationRanking> getMyRanking(int formationId) async {
    try {
      final response = await apiClient.dio.get('/stagiaire/formations/$formationId/classement');
      return UserFormationRanking.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de votre classement: $e');
    }
  }
}
