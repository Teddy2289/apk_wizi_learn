import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/stagiaire_profile_model.dart';
import 'package:flutter/foundation.dart';

class StagiaireProfileRepository {
  final ApiClient apiClient;

  StagiaireProfileRepository({required this.apiClient});

  /// Fetch complete student profile
  Future<StagiaireProfile> getProfileById(int stagiaireId) async {
    try {
      final response = await apiClient.get(
        '/formateur/stagiaire/$stagiaireId/stats',
      );
      
      debugPrint('📊 Profil stagiaire reçu: ${response.data}');
      return StagiaireProfile.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Erreur chargement profil stagiaire: $e');
      rethrow;
    }
  }

  /// Get formateur notes for a student
  Future<List<FormateurNote>> getNotes(int stagiaireId) async {
    try {
      final response = await apiClient.get(
        '/formateur/stagiaire/$stagiaireId/notes',
      );
      
      final notes = (response.data['notes'] as List?)
              ?.map((n) => FormateurNote.fromJson(n))
              .toList() ??
          [];
      
      return notes;
    } catch (e) {
      debugPrint('❌ Erreur chargement notes: $e');
      return [];
    }
  }

  /// Add a private note for a student
  Future<bool> addNote(int stagiaireId, String content) async {
    try {
      await apiClient.post(
        '/formateur/stagiaire/$stagiaireId/note',
        data: {'content': content},
      );
      
      debugPrint('✅ Note ajoutée avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur ajout note: $e');
      return false;
    }
  }

  /// Send direct message to student
  Future<bool> sendMessage(int stagiaireId, String title, String body) async {
    try {
      await apiClient.post(
        '/formateur/send-notification',
        data: {
          'recipient_ids': [stagiaireId],
          'title': title,
          'body': body,
          'data': {},
        },
      );
      
      debugPrint('✅ Message envoyé avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur envoi message: $e');
      return false;
    }
  }
}

/// Model for formateur's private notes
class FormateurNote {
  final int id;
  final String content;
  final String createdAt;

  FormateurNote({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  factory FormateurNote.fromJson(Map<String, dynamic> json) {
    return FormateurNote(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
