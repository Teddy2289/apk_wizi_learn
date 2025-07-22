import 'package:flutter/cupertino.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/features/auth/data/models/formation_with_medias.dart';
import 'package:wizi_learn/features/auth/data/models/media_model.dart';

class MediaRepository {
  final ApiClient apiClient;

  MediaRepository({required this.apiClient});

  Future<List<Media>> getAstuces(int formationId) async {
    final response = await apiClient.get(AppConstants.astucesByFormation(formationId));
    print('Astuces reçues : ${response.data}');

    if (response.data is List) {
      return (response.data as List).map((e) => Media.fromJson(e)).toList();
    } else {
      print('⚠ La réponse des astuces n’est pas une liste : ${response.data}');
      return [];
    }
  }

  Future<List<Media>> getTutoriels(int formationId) async {
    final response = await apiClient.get(AppConstants.tutorielsByFormation(formationId));
    print('Tutoriels reçus : ${response.data}');

    if (response.data is List) {
      return (response.data as List).map((e) => Media.fromJson(e)).toList();
    } else {
      print('⚠ La réponse des tutoriels n’est pas une liste : ${response.data}');
      return [];
    }
  }

  Future<List<FormationWithMedias>> getFormationsAvecMedias(int userId) async {
    final response = await apiClient.get('/stagiaire/$userId/formations');

    final formationsJson = response.data['data'] as List;

    return formationsJson
        .map((json) => FormationWithMedias.fromJson(json))
        .toList();
  }

  Future<bool> markMediaAsWatched(int mediaId) async {
    try {
      final response = await apiClient.post(
        '/medias/$mediaId/watched',
        data: {}, // Pas besoin de body car le backend récupère le stagiaire du token
      );
      return response.data['success'] == true;
    } catch (e) {
      debugPrint("Erreur lors du marquage comme vu: $e");
      return false;
    }
  }

  Future<Set<int>> getWatchedMediaIds() async {
    try {
      final response = await apiClient.get('/medias/formations-with-status');
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
