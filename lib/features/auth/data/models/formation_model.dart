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
  final double tarif;
  final String? certification;
  final int statut;
  final String duree;
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
  });
  factory Formation.fromJson(Map<String, dynamic> json) {
    // Sécuriser accès aux sous-objets
    final rawCategory = json['formation'] ?? {};
    final rawStagiaires = (json['stagiaires'] as List?) ?? [];

    return Formation(
      id: json['id'] is int ? json['id'] : 0,
      titre: _cleanString(json['titre'], fallback: 'Titre inconnu'),
      description: _cleanString(json['description'], fallback: 'Description non disponible'),
      prerequis: _cleanNullableString(json['prerequis']),
      imageUrl: _cleanNullableString(json['image_url']),
      cursusPdf: _cleanNullableString(json['cursus_pdf']),
      tarif: _parseDouble(json['tarif']),
      certification: _cleanNullableString(json['certification']),
      statut: json['statut'] is int ? json['statut'] : 0,
      duree: _cleanString(json['duree'], fallback: '0'),
      category: FormationCategory.fromJson(rawCategory),
      stagiaires: rawStagiaires
          .where((s) => s != null)
          .map((s) => StagiaireModel.fromJson(s))
          .toList(),
      formateur: json['formateur'] != null && json['formateur'] is Map && json['formateur'].isNotEmpty
          ? FormateurModel.fromJson(json['formateur'])
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
      id: json['id'],
      titre: json['titre'],
      categorie: json['categorie'],
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
