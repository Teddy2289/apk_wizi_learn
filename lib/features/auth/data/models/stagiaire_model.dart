import 'package:equatable/equatable.dart';

// Models
class StagiaireModel extends Equatable {
  final int id;
  final String prenom;
  final String civilite;
  final String telephone;
  final String adresse;
  final String dateNaissance;
  final String ville;
  final String codePostal;
  final String dateDebutFormation;
  final String dateFinFormation;
  final String dateInscription;
  final String role;
  final int statut;
  final int userId;

  const StagiaireModel({
    required this.id,
    required this.prenom,
    required this.civilite,
    required this.telephone,
    required this.adresse,
    required this.dateNaissance,
    required this.ville,
    required this.codePostal,
    required this.dateDebutFormation,
    required this.dateFinFormation,
    required this.dateInscription,
    required this.role,
    required this.statut,
    required this.userId,
  });

  factory StagiaireModel.fromJson(Map<String, dynamic> json) {
    return StagiaireModel(
      id: json['id'],
      prenom: json['prenom'],
      civilite: json['civilite'],
      telephone: json['telephone'],
      adresse: json['adresse'],
      dateNaissance: json['date_naissance'],
      ville: json['ville'],
      codePostal: json['code_postal'],
      dateDebutFormation: json['date_debut_formation'],
      dateFinFormation: json['date_fin_formation'] ?? '',
      dateInscription: json['date_inscription'],
      role: json['role'],
      statut: json['statut'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prenom': prenom,
      'civilite': civilite,
      'telephone': telephone,
      'adresse': adresse,
      'date_naissance': dateNaissance,
      'ville': ville,
      'code_postal': codePostal,
      'date_debut_formation': dateDebutFormation,
      'date_fin_formation': dateFinFormation,
      'date_inscription': dateInscription,
      'role': role,
      'statut': statut,
      'user_id': userId,
    };
  }

  @override
  List<Object?> get props => [
    id,
    prenom,
    civilite,
    telephone,
    adresse,
    dateNaissance,
    ville,
    codePostal,
    dateDebutFormation,
    dateFinFormation,
    dateInscription,
    role,
    statut,
    userId,
  ];
}
