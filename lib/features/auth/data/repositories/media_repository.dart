import 'package:flutter/cupertino.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/features/auth/data/models/formation_with_medias.dart';
import 'package:wizi_learn/features/auth/data/models/media_model.dart';

class MediaRepository {
  final ApiClient apiClient;

  MediaRepository({required this.apiClient});

  Future<List<Media>> getAstuces(int formationId) async {
    try {
      final response = await apiClient.get(
        AppConstants.astucesByFormation(formationId),
      );
      
      final dynamic data = response.data;
      if (data == null) return [];

      // Harmonisation: Node might return { data: [...] }, Laravel directly [...]
      final List<dynamic> list;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        list = data['data'] as List;
      } else if (data is List) {
        list = data;
      } else {
        return [];
      }

      return list.map((e) => Media.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching astuces: $e');
      return [];
    }
  }

  Future<List<Media>> getTutoriels(int formationId) async {
    try {
      final response = await apiClient.get(
        AppConstants.tutorielsByFormation(formationId),
      );
      
      final dynamic data = response.data;
      if (data == null) return [];

      final List<dynamic> list;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        list = data['data'] as List;
      } else if (data is List) {
        list = data;
      } else {
        return [];
      }

      return list.map((e) => Media.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching tutoriels: $e');
      return [];
    }
  }

  Future<List<FormationWithMedias>> getFormationsAvecMedias(int userId) async {
    try {
      final response = await apiClient.get('/stagiaire/$userId/formations');
      
      final dynamic data = response.data;
      if (data == null) return [];

      final List<dynamic> list;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        list = data['data'] as List;
      } else if (data is List) {
        list = data;
      } else {
        return [];
      }

      return list.map((json) => FormationWithMedias.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching formations: $e');
      return [];
    }
  }

  Future<bool> markMediaAsWatched(int mediaId) async {
    try {
      final response = await apiClient.post('/medias/$mediaId/watched');
      final data = response.data;
      return (data is Map && data['success'] == true) || 
             (data is Map && data['message'] != null);
    } catch (e) {
      debugPrint('Error marking media as watched: $e');
      return false;
    }
  }

  // New helper: return full server payload to access newAchievements
  Future<Map<String, dynamic>> markMediaAsWatchedWithResponse(
    int mediaId,
  ) async {
    try {
      final response = await apiClient.post(
        '/medias/$mediaId/watched',
        data: {},
      );
      return (response.data is Map<String, dynamic>)
          ? response.data as Map<String, dynamic>
          : {'success': false};
    } catch (e) {
      debugPrint('Erreur lors du marquage comme vu (avec réponse): $e');
      return {'success': false};
    }
  }

  Future<Set<int>> getWatchedMediaIds() async {
    try {
      final response = await apiClient.get('/medias/formations-with-status');
      final dynamic data = response.data;
      
      if (data is! List) return {};

      final watchedMediaIds = <int>{};
      for (final formation in data) {
        final medias = formation['medias'] as List?;
        if (medias == null) continue;

        for (final media in medias) {
          final id = media['id'] as int?;
          if (id == null) continue;

          // Laravel returns stagiaires list, Node might return pivot directly or formatted
          final stagiaires = media['stagiaires'] as List?;
          if (stagiaires != null && stagiaires.isNotEmpty) {
            for (final stagiaire in stagiaires) {
              final pivot = stagiaire['pivot'] as Map<String, dynamic>?;
              if (pivot != null && (pivot['is_watched'] == 1 || pivot['is_watched'] == true)) {
                watchedMediaIds.add(id);
              }
            }
          }
        }
      }
      return watchedMediaIds;
    } catch (e) {
      debugPrint('Error fetching watched media IDs: $e');
      return {};
    }
  }
}
