import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/stagiaire_model.dart';
class Formation {
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
    required this.stagiaires
  });

  factory Formation.fromJson(Map<String, dynamic> json) {
    return Formation(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      prerequis: json['prerequis'],
      imageUrl: json['image_url'],
      cursusPdf: json['cursus_pdf'],
      tarif: double.tryParse(json['tarif']?.toString() ?? '0') ?? 0,
      certification: json['certification'],
      statut: json['statut'] ?? 0,
      duree: json['duree'] ?? '',
      category: FormationCategory.fromJson(json['formation'] ?? {}),
      stagiaires: json['stagiaires'] != null
          ? (json['stagiaires'] as List).map((s) => StagiaireModel.fromJson(s)).toList()
          : null,
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
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      categorie: json['categorie'] ?? '',
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