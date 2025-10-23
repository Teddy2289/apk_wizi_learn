import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/stagiaire_model.dart';
import 'package:wizi_learn/features/auth/data/models/formateur_model.dart';

class Formation {
  static String _cleanString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final s = value.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  static String? _cleanNullableString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }

  final int id;
  final String titre;
  final String description;
  final String? prerequis;
  final String? imageUrl;
  final String? cursusPdf;
  final String? cursusPdfUrl;
  final double tarif;
  final String? certification;
  final int statut;
  final String duree;
  final String? objectifs;
  final String? programme;
  final String? modalites;
  final String? modalitesAccompagnement;
  final String? moyensPedagogiques;
  final String? modalitesSuivi;
  final String? evaluation;
  final String? lieu;
  final String? niveau;
  final String? publicCible;
  final int? nombreParticipants;
  final FormationCategory category;
  final List<StagiaireModel>? stagiaires;
  final FormateurModel? formateur;
  final String? dateDebut;
  final String? dateFin;

  // Models
  Formation({
    required this.id,
    required this.titre,
    required this.description,
    this.prerequis,
    this.imageUrl,
    this.cursusPdf,
    required this.tarif,
    this.certification,
    required this.statut,
    required this.duree,
    required this.category,
    required this.stagiaires,
    this.formateur,
    this.dateDebut,
    this.dateFin,
    this.objectifs,
    this.programme,
    this.modalites,
    this.modalitesAccompagnement,
    this.moyensPedagogiques,
    this.modalitesSuivi,
    this.evaluation,
    this.lieu,
    this.niveau,
    this.publicCible,
    this.nombreParticipants,
    this.cursusPdfUrl,
  });
  factory Formation.fromJson(Map<String, dynamic> json) {
    // Sécuriser accès aux sous-objets
    final rawCategory =
        (json['formation'] is Map)
            ? (json['formation'] as Map<String, dynamic>)
            : <String, dynamic>{};
    final rawStagiaires =
        (json['stagiaires'] is List)
            ? (json['stagiaires'] as List)
            : <dynamic>[];

    return Formation(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      titre: _cleanString(json['titre'], fallback: 'Titre inconnu'),
      description: _cleanString(
        json['description'],
        fallback: 'Description non disponible',
      ),
      prerequis: _cleanNullableString(json['prerequis']),
      imageUrl: _cleanNullableString(json['image_url']),
      cursusPdf: _cleanNullableString(json['cursus_pdf']),
      cursusPdfUrl: _cleanNullableString(
        json['cursusPdfUrl'] ?? json['cursus_pdf'] ?? json['cursusPdfUrl'],
      ),
      tarif: _parseDouble(json['tarif']),
      certification: _cleanNullableString(json['certification']),
      statut:
          json['statut'] is int
              ? json['statut']
              : int.tryParse(json['statut']?.toString() ?? '') ?? 0,
      duree: _cleanString(json['duree'], fallback: '0'),
      objectifs: _cleanNullableString(json['objectifs']),
      programme: _cleanNullableString(json['programme']),
      modalites: _cleanNullableString(json['modalites']),
      modalitesAccompagnement: _cleanNullableString(
        json['modalites_accompagnement'],
      ),
      moyensPedagogiques: _cleanNullableString(json['moyens_pedagogiques']),
      modalitesSuivi: _cleanNullableString(json['modalites_suivi']),
      evaluation: _cleanNullableString(json['evaluation']),
      lieu: _cleanNullableString(json['lieu']),
      niveau: _cleanNullableString(json['niveau']),
      publicCible: _cleanNullableString(json['public_cible']),
      nombreParticipants:
          json['nombre_participants'] is int
              ? json['nombre_participants']
              : (int.tryParse(json['nombre_participants']?.toString() ?? '') ??
                  null),
      category: FormationCategory.fromJson(rawCategory),
      stagiaires:
          rawStagiaires
              .where((s) => s != null && s is Map)
              .map(
                (s) =>
                    StagiaireModel.fromJson((s ?? {}) as Map<String, dynamic>),
              )
              .toList(),
      formateur:
          json['formateur'] is Map && (json['formateur'] as Map).isNotEmpty
              ? FormateurModel.fromJson(
                (json['formateur'] as Map).cast<String, dynamic>(),
              )
              : null,
      dateDebut: _cleanNullableString(json['date_debut']),
      dateFin: _cleanNullableString(json['date_fin']),
    );
  }
}

class FormationCategory {
  final int id;
  final String titre;
  final String categorie;

  FormationCategory({
    required this.id,
    required this.titre,
    required this.categorie,
  });

  factory FormationCategory.fromJson(Map<String, dynamic> json) {
    return FormationCategory(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      titre: json['titre']?.toString() ?? 'Titre inconnu',
      categorie: json['categorie']?.toString() ?? 'Autre',
    );
  }

  Color get color {
    switch (categorie) {
      case 'Bureautique':
        return const Color(0xFF3D9BE9);
      case 'Langues':
        return const Color(0xFFA55E6E);
      case 'Internet':
        return const Color(0xFFFFC533);
      case 'Création':
        return const Color(0xFF9392BE);
      default:
        return Colors.grey;
    }
  }
}
