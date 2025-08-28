import 'package:flutter/cupertino.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/features/auth/data/models/formation_with_medias.dart';
import 'package:wizi_learn/features/auth/data/models/media_model.dart';

class MediaRepository {
  final ApiClient apiClient;

  MediaRepository({required this.apiClient});

  Future<List<Media>> getAstuces(int formationId) async {
    final response = await apiClient.get(
      AppConstants.astucesByFormation(formationId),
    );
    print('Astuces reçues : ${response.data}');

    if (response.data is List) {
      return (response.data as List).map((e) => Media.fromJson(e)).toList();
    } else {
      print('⚠ La réponse des astuces n’est pas une liste : ${response.data}');
      return [];
    }
  }

  Future<List<Media>> getTutoriels(int formationId) async {
    final response = await apiClient.get(
      AppConstants.tutorielsByFormation(formationId),
    );
    print('Tutoriels reçus : ${response.data}');

    if (response.data is List) {
      return (response.data as List).map((e) => Media.fromJson(e)).toList();
    } else {
      print(
        '⚠ La réponse des tutoriels n’est pas une liste : ${response.data}',
      );
      return [];
    }
  }

  Future<List<FormationWithMedias>> getFormationsAvecMedias(int userId) async {
    try {
      final response = await apiClient.get('/stagiaire/$userId/formations');

      if (response.data == null) {
        debugPrint("Réponse nulle du serveur");
        return [];
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        debugPrint("Format de réponse invalide: ${data.runtimeType}");
        return [];
      }

      final formationsJson = data['data'] as List?;

      if (formationsJson == null) {
        debugPrint("Aucune donnée de formation trouvée");
        return [];
      }

      return formationsJson
          .map((json) => FormationWithMedias.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Erreur lors de la récupération des formations: $e");
      return [];
    }
  }

  Future<bool> markMediaAsWatched(int mediaId) async {
    try {
      final response = await apiClient.post(
        '/medias/$mediaId/watched',
        data:
            {}, // Pas besoin de body car le backend récupère le stagiaire du token
      );
      return response.data['success'] == true;
    } catch (e) {
      debugPrint("Erreur lors du marquage comme vu: $e");
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
      debugPrint('Erreur lors du marquage comme vu (avec réponse 2): $response');

      if (response.data is List) {
        final formations = response.data as List;
        final watchedMediaIds = <int>{};

        for (final formation in formations) {
          final medias = formation['medias'] as List?;
          if (medias != null) {
            for (final media in medias) {
              final stagiaires = media['stagiaires'] as List?;
              if (stagiaires != null && stagiaires.isNotEmpty) {
                for (final stagiaire in stagiaires) {
                  final pivot = stagiaire['pivot'] as Map<String, dynamic>?;
                  if (pivot != null && pivot['is_watched'] == 1) {
                    watchedMediaIds.add(media['id'] as int);
                  }
                }
              }
            }
          }
        }
        return watchedMediaIds;
      }
      return {};
    } catch (e) {
      debugPrint("Erreur lors de la récupération des médias vus: $e");
      return {};
    }
  }
}
