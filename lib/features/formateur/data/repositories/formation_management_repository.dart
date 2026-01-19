import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/formation_management_model.dart';
import 'package:flutter/foundation.dart';

class FormationManagementRepository {
  final ApiClient apiClient;

  FormationManagementRepository({required this.apiClient});

  /// Get all available formations with stats
  Future<List<FormationWithStats>> getAvailableFormations() async {
    try {
      final response = await apiClient.get('/formateur/formations/available');

      final formations = (response.data['formations'] as List?)
              ?.map((f) => FormationWithStats.fromJson(f))
              .toList() ??
          [];

      debugPrint('📚 ${formations.length} formations récupérées');
      return formations;
    } catch (e) {
      debugPrint('❌ Erreur chargement formations: $e');
      rethrow;
    }
  }

  /// Get stagiaires assigned to a formation
  Future<List<StagiaireInFormation>> getStagiairesByFormation(
      int formationId) async {
    try {
      final response = await apiClient.get(
        '/formateur/formations/$formationId/stagiaires',
      );

      final stagiaires = (response.data['stagiaires'] as List?)
              ?.map((s) => StagiaireInFormation.fromJson(s))
              .toList() ??
          [];

      return stagiaires;
    } catch (e) {
      debugPrint('❌ Erreur chargement stagiaires: $e');
      rethrow;
    }
  }

  /// Get unassigned stagiaires for a formation
  Future<List<UnassignedStagiaire>> getUnassignedStagiaires(
      int formationId) async {
    try {
      final response = await apiClient.get(
        '/formateur/stagiaires/unassigned/$formationId',
      );

      final stagiaires = (response.data['stagiaires'] as List?)
              ?.map((s) => UnassignedStagiaire.fromJson(s))
              .toList() ??
          [];

      return stagiaires;
    } catch (e) {
      debugPrint('❌ Erreur chargement stagiaires non assignés: $e');
      rethrow;
    }
  }

  /// Assign formation to stagiaires
  Future<bool> assignFormation({
    required int formationId,
    required List<int> stagiaireIds,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      await apiClient.post(
        '/formateur/formations/$formationId/assign',
        data: {
          'stagiaire_ids': stagiaireIds,
          if (dateDebut != null)
            'date_debut': dateDebut.toIso8601String().split('T')[0],
          if (dateFin != null)
            'date_fin': dateFin.toIso8601String().split('T')[0],
        },
      );

      debugPrint('✅ Formation assignée à ${stagiaireIds.length} stagiaires');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur assignation formation: $e');
      return false;
    }
  }

  /// Get formation statistics
  Future<FormationStats> getFormationStats(int formationId) async {
    try {
      final response = await apiClient.get(
        '/formateur/formations/$formationId/stats',
      );

      return FormationStats.fromJson(response.data['stats'] ?? {});
    } catch (e) {
      debugPrint('❌ Erreur chargement stats formation: $e');
      rethrow;
    }
  }

  /// Update formation schedule
  Future<bool> updateSchedule({
    required int formationId,
    required List<int> stagiaireIds,
    required DateTime dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      await apiClient.put(
        '/formateur/formations/$formationId/schedule',
        data: {
          'stagiaire_ids': stagiaireIds,
          'date_debut': dateDebut.toIso8601String().split('T')[0],
          if (dateFin != null)
            'date_fin': dateFin.toIso8601String().split('T')[0],
        },
      );

      debugPrint('✅ Calendrier mis à jour');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur mise à jour calendrier: $e');
      return false;
    }
  }
}
