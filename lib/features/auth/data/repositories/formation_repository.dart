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
    final response = await apiClient.get(AppConstants.catalogueFormation);
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
      '${AppConstants.catalogueFormation}/$id',
    );
    final data = response.data['catalogueFormation'];

    return Formation.fromJson(data);
  }

  Future<List<Formation>> getRandomFormations(int count) async {
    final allFormations = await getFormations();

    if (allFormations.isEmpty) {
      // debugPrint('Aucune formation trouvée dans la base.');
      return [];
    }

    allFormations.shuffle();
    return allFormations.take(count).toList();
  }

  Future<List<Formation>> getCatalogueFormations({int? stagiaireId}) async {
    try {
      final path = stagiaireId != null 
          ? '/stagiaire/$stagiaireId/formations' 
          : AppConstants.formationStagiaire;
      final response = await apiClient.get(path);
      final data = response.data;

      // debugPrint('🟡 DEBUG getCatalogueFormations: Reçu type ${data.runtimeType}');

      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['data'] is List) {
        list = data['data'];
      } else if (data is Map && data['formations'] is List) {
        // Au cas où le champ s'appelle 'formations'
        list = data['formations'];
      } else {
        debugPrint('🔴 DEBUG getCatalogueFormations: Structure inattendue. Data: $data');
        throw Exception('Structure inattendue de la réponse: type ${data.runtimeType}');
      }

      final List<Formation> catalogueFormations = [];
      for (final formationItem in list) {
        try {
          if (formationItem == null) continue;
          
          final catalogue = formationItem['catalogue'] ?? {};
          final formation = formationItem['formation'] ?? formationItem; // Fallback si plat
          final formateur = formationItem['formateur'] ?? {};
          final pivot = formationItem['pivot'] ?? {};

          // Extraction des dates depuis le pivot
          final String? dateDebut = pivot['date_debut']?.toString() ?? formationItem['date_debut']?.toString();
          final String? dateFin = pivot['date_fin']?.toString() ?? formationItem['date_fin']?.toString();

          catalogueFormations.add(
            Formation(
              id: formation['id'] is int ? formation['id'] : int.tryParse(formation['id']?.toString() ?? '0') ?? 0,
              titre: formation['titre'] ?? 'Titre inconnu',
              description: formation['description'] ?? 'Description non disponible',
              prerequis: catalogue['prerequis'],
              imageUrl: catalogue['image_url'],
              cursusPdf: catalogue['cursus_pdf'],
              cursusPdfUrl: catalogue['cursusPdfUrl'] ?? catalogue['cursus_pdf'],
              tarif: double.tryParse(catalogue['tarif']?.toString() ?? '0') ?? 0,
              certification: catalogue['certification'],
              statut: formation['statut'] is int ? formation['statut'] : int.tryParse(formation['statut']?.toString() ?? '0') ?? 1,
              duree: formation['duree']?.toString() ?? '0',
              objectifs: catalogue['objectifs'] ?? formation['objectifs'],
              programme: catalogue['programme'] ?? formation['programme'],
              modalites: catalogue['modalites'] ?? formation['modalites'],
              modalitesAccompagnement: catalogue['modalites_accompagnement'] ?? formation['modalites_accompagnement'],
              moyensPedagogiques: catalogue['moyens_pedagogiques'] ?? formation['moyens_pedagogiques'],
              modalitesSuivi: catalogue['modalites_suivi'] ?? formation['modalites_suivi'],
              evaluation: catalogue['evaluation'] ?? formation['evaluation'],
              lieu: catalogue['lieu'] ?? formation['lieu'],
              niveau: catalogue['niveau'] ?? formation['niveau'],
              publicCible: catalogue['public_cible'] ?? formation['public_cible'],
              nombreParticipants: formation['nombre_participants'] is int ? formation['nombre_participants'] : int.tryParse(formation['nombre_participants']?.toString() ?? '0'),
              category: FormationCategory(
                id: catalogue['id'] ?? formation['id'] ?? 0,
                titre: catalogue['titre'] ?? formation['titre'] ?? 'Titre inconnu',
                categorie: catalogue['categorie'] ?? formation['categorie'] ?? 'Autre',
              ),
              stagiaires: (catalogue['stagiaires'] as List?)
                  ?.map((s) => StagiaireModel.fromJson(s ?? {}))
                  .toList(),
              formateur: formateur.isNotEmpty ? FormateurModel.fromJson(formateur) : null,
              dateDebut: dateDebut,
              dateFin: dateFin,
              stats: formationItem['stats'] != null ? FormationStats.fromJson(formationItem['stats']) : null,
            ),
          );
        } catch (e) {
          debugPrint('Erreur lors du parsing d\'une formation: $e');
          continue; 
        }
      }

      return catalogueFormations;
    } catch (e) {
      debugPrint('Erreur getCatalogueFormations: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> inscrireAFormation(int formationId) async {
    try {
      debugPrint(
        '🟡 DEBUG: Appel API vers /stagiaire/inscription-catalogue-formation',
      );
      debugPrint(
        '🟡 DEBUG: Données envoyées: {"catalogue_formation_id": $formationId}',
      );

      final response = await apiClient.post(
        '/stagiaire/inscription-catalogue-formation', // CORRIGÉ : même route que le backend
        data: {'catalogue_formation_id': formationId},
      );

      debugPrint('🟢 DEBUG: Réponse reçue - Status: ${response.statusCode}');
      debugPrint('🟢 DEBUG: Données de réponse: ${response.data}');

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
      debugPrint('🔴 DEBUG: Erreur dans inscrireAFormation: $e');
      rethrow;
    }
  }
}
