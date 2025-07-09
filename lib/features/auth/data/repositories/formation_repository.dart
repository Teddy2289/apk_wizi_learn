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
      return data.map((e) => Formation.fromJson(e)).toList();
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
    final response =
        await apiClient.get('${AppConstants.catalogue_formation}/$id');
    final data = response.data['catalogueFormation'];

    return Formation.fromJson(data);
  }

  Future<List<Formation>> getRandomFormations(int count) async {
    final allFormations = await getFormations();
    allFormations.shuffle();
    return allFormations.take(count).toList();
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

            debugPrint('Formation: \n  titre: ${formation['titre']} \n  date_debut: $dateDebut \n  date_fin: $dateFin');

            catalogueFormations.add(Formation(
              id: formation['id'] ?? 0,
              titre: formation['titre'] ?? 'Titre inconnu',
              description: formation['description'] ?? 'Description non disponible',
              prerequis: catalogue['prerequis'],
              imageUrl: catalogue['image_url'],
              cursusPdf: catalogue['cursus_pdf'],
              tarif: double.tryParse(catalogue['tarif']?.toString() ?? '0') ?? 0,
              certification: catalogue['certification'],
              statut: formation['statut'] ?? 0,
              duree: formation['duree']?.toString() ?? '0',
              category: FormationCategory(
                id: formation['id'] ?? 0,
                titre: formation['titre'] ?? 'Titre inconnu',
                categorie: formation['categorie'] ?? 'Autre',
              ),
              stagiaires: (catalogue['stagiaires'] as List?)
                  ?.map((s) => StagiaireModel.fromJson(s ?? {}))
                  .toList(),
              formateur: formateur.isNotEmpty
                  ? FormateurModel.fromJson(formateur)
                  : null,
              dateDebut: dateDebut,
              dateFin: dateFin,
            ));
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
  Future<void> inscrireAFormation(int formationId) async {
    final response = await apiClient.post(
      '/stagiaire/inscription-catalogue-formation',
      data: {'catalogue_formation_id': formationId},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur lors de l\'inscription');
    }
  }
}
