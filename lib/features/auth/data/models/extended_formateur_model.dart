class ExtendedFormateur {
  final int id;
  final String? civilite;
  final String prenom;
  final String nom;
  final String telephone;
  final String? image;
  final List<ExtendedFormation> formations;

  ExtendedFormateur({
    required this.id,
    this.civilite,
    required this.prenom,
    required this.nom,
    required this.telephone,
    this.image,
    required this.formations,
  });

  factory ExtendedFormateur.fromJson(Map<String, dynamic> json) {
    return ExtendedFormateur(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      civilite: json['civilite'],
      prenom: json['prenom']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      telephone: json['telephone']?.toString() ?? '',
      image: json['image'],
      formations:
          json['formations'] != null
              ? (json['formations'] as List)
                  .map((formation) => ExtendedFormation.fromJson(formation))
                  .toList()
              : [],
    );
  }
}

class ExtendedFormation {
  final int id;
  final String titre;
  final String description;
  final String duree;
  final String tarif;
  final int statut;
  final String? imageUrl;
  final ExtendedFormationCategorie? formation;

  ExtendedFormation({
    required this.id,
    required this.titre,
    required this.description,
    required this.duree,
    required this.tarif,
    required this.statut,
    this.imageUrl,
    this.formation,
  });

  factory ExtendedFormation.fromJson(Map<String, dynamic> json) {
    return ExtendedFormation(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      titre: json['titre']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      duree: json['duree']?.toString() ?? '',
      tarif: json['tarif']?.toString() ?? '',
      statut:
          json['statut'] is int
              ? json['statut']
              : int.tryParse(json['statut']?.toString() ?? '') ?? 0,
      imageUrl: json['image_url'],
      formation:
          json['formation'] != null
              ? ExtendedFormationCategorie.fromJson(json['formation'])
              : null,
    );
  }
}

class ExtendedFormationCategorie {
  final int id;
  final String titre;
  final String categorie;
  final String? icon;

  ExtendedFormationCategorie({
    required this.id,
    required this.titre,
    required this.categorie,
    this.icon,
  });

  factory ExtendedFormationCategorie.fromJson(Map<String, dynamic> json) {
    return ExtendedFormationCategorie(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      titre: json['titre']?.toString() ?? '',
      categorie: json['categorie']?.toString() ?? '',
      icon: json['icon'],
    );
  }
}
