import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/formation_model.dart';
import 'package:wizi_learn/features/auth/data/models/stagiaire_model.dart';
import 'package:wizi_learn/features/auth/data/models/formateur_model.dart';

class FormationRepository {
  final ApiClient apiClient;

  FormationRepository({required this.apiClient});

  Future<List<Formation>> getFormations() async {
    final response = await apiClient.get(AppConstants.catalogue_formation);
    final data = response.data;

    if (data is List) {
      return data
          .where((e) => e != null)
          .map((e) => Formation.fromJson(e))
          .toList();
    } else if (data is Map && data['data'] is List) {
      return (data['data'] as List).map((e) => Formation.fromJson(e)).toList();
    } else {
      throw Exception('Format de réponse inattendu');
    }
  }

  Future<List<Formation>> getFormationsByCategory(String category) async {
    final formations = await getFormations();
    return formations
        .where((formation) => formation.category.categorie == category)
        .toList();
  }

  Future<Formation> getFormationDetail(int id) async {
    final response = await apiClient.get(
      '${AppConstants.catalogue_formation}/$id',
    );
    final data = response.data['catalogueFormation'];

    return Formation.fromJson(data);
  }

  Future<List<Formation>> getRandomFormations(int count) async {
    final allFormations = await getFormations();

    if (allFormations.isEmpty) {
      debugPrint('Aucune formation trouvée dans la base.');
      return [];
    }

    allFormations.shuffle();
    return allFormations.take(count).toList();
  }

  /// Retourne des formations qui changent quotidiennement de manière déterministe
  /// Les mêmes formations sont affichées pendant toute la journée
  Future<List<Formation>> getDailyFormations(int count) async {
    final allFormations = await getFormations();

    if (allFormations.isEmpty) {
      debugPrint('Aucune formation trouvée dans la base.');
      return [];
    }

    // Créer une graine (seed) basée sur la date du jour
    // Cette graine sera la même pour toute la journée
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final seed = now.year * 1000 + dayOfYear;

    // Utiliser Random avec seed pour rotation déterministe
    final random = Random(seed);
    final shuffled = List<Formation>.from(allFormations);

    // Fisher-Yates shuffle avec seed pour mélange déterministe
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }

    debugPrint('🔄 Rotation quotidienne - Seed: $seed (jour ${now.day}/${now.month}/${now.year})');
    return shuffled.take(count).toList();
  }

  Future<List<Formation>> getCatalogueFormations({int? stagiaireId}) async {
    try {
      final response = await apiClient.get(AppConstants.formationStagiaire);
      final data = response.data;

      if (data is Map && data['data'] is List) {
        final List<Formation> catalogueFormations = [];
        final formationList = data['data'];

        for (final formationItem in formationList) {
          try {
            final catalogue = formationItem['catalogue'] ?? {};
            final formation = formationItem['formation'] ?? {};
            final formateur = formationItem['formateur'] ?? {};
            final pivot = formationItem['pivot'] ?? {};

            // Extraction des dates depuis le pivot
            final String? dateDebut = pivot['date_debut']?.toString();
            final String? dateFin = pivot['date_fin']?.toString();

            debugPrint(
              'Formation: \n  titre: ${formation['titre']} \n  date_debut: $dateDebut \n  date_fin: $dateFin',
            );

            catalogueFormations.add(
              Formation(
                id: formation['id'] ?? 0,
                titre: formation['titre'] ?? 'Titre inconnu',
                description:
                    formation['description'] ?? 'Description non disponible',
                prerequis: catalogue['prerequis'],
                imageUrl: catalogue['image_url'],
                cursusPdf: catalogue['cursus_pdf'],
                cursusPdfUrl:
                    catalogue['cursusPdfUrl'] ??
                    catalogue['cursus_pdf'] ??
                    null,
                tarif:
                    double.tryParse(catalogue['tarif']?.toString() ?? '0') ?? 0,
                certification: catalogue['certification'],
                statut: formation['statut'] ?? 0,
                duree: formation['duree']?.toString() ?? '0',
                objectifs: catalogue['objectifs'] ?? formation['objectifs'],
                programme: catalogue['programme'] ?? formation['programme'],
                modalites: catalogue['modalites'] ?? formation['modalites'],
                modalitesAccompagnement:
                    catalogue['modalites_accompagnement'] ??
                    formation['modalites_accompagnement'],
                moyensPedagogiques:
                    catalogue['moyens_pedagogiques'] ??
                    formation['moyens_pedagogiques'],
                modalitesSuivi:
                    catalogue['modalites_suivi'] ??
                    formation['modalites_suivi'],
                evaluation: catalogue['evaluation'] ?? formation['evaluation'],
                lieu: catalogue['lieu'] ?? formation['lieu'],
                niveau: catalogue['niveau'] ?? formation['niveau'],
                publicCible:
                    catalogue['public_cible'] ?? formation['public_cible'],
                nombreParticipants:
                    catalogue['nombre_participants'] ??
                    formation['nombre_participants'],
                category: FormationCategory(
                  id: catalogue['id'] ?? formation['id'] ?? 0,
                  titre:
                      catalogue['titre'] ??
                      formation['titre'] ??
                      'Titre inconnu',
                  categorie:
                      catalogue['categorie'] ??
                      formation['categorie'] ??
                      'Autre',
                ),
                stagiaires:
                    (catalogue['stagiaires'] as List?)
                        ?.map((s) => StagiaireModel.fromJson(s ?? {}))
                        .toList(),
                formateur:
                    formateur.isNotEmpty
                        ? FormateurModel.fromJson(formateur)
                        : null,
                dateDebut: dateDebut,
                dateFin: dateFin,
              ),
            );
          } catch (e) {
            debugPrint('Erreur lors du parsing d\'une formation: $e');
            continue; // Continue avec les formations suivantes
          }
        }

        return catalogueFormations;
      }

      throw Exception('Structure inattendue de la réponse');
    } catch (e) {
      debugPrint('Erreur getCatalogueFormations: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> inscrireAFormation(int formationId) async {
    try {
      print(
        '🟡 DEBUG: Appel API vers /stagiaire/inscription-catalogue-formation',
      );
      print(
        '🟡 DEBUG: Données envoyées: {"catalogue_formation_id": $formationId}',
      );

      final response = await apiClient.post(
        '/stagiaire/inscription-catalogue-formation', // CORRIGÉ : même route que le backend
        data: {'catalogue_formation_id': formationId},
      );

      print('🟢 DEBUG: Réponse reçue - Status: ${response.statusCode}');
      print('🟢 DEBUG: Données de réponse: ${response.data}');

      // Accepter les codes 200, 201
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } catch (e) {
      print('🔴 DEBUG: Erreur dans inscrireAFormation: $e');
      rethrow;
    }
  }
}
