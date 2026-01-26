
/// Model for Formation with assignment stats
class FormationWithStats {
  final int id;
  final String titre;
  final String categorie;
  final String? description;
  final String? image;
  final int nbStagiaires;
  final int nbVideos;
  final int dureeEstimee;

  FormationWithStats({
    required this.id,
    required this.titre,
    required this.categorie,
    this.description,
    this.image,
    required this.nbStagiaires,
    required this.nbVideos,
    required this.dureeEstimee,
  });

  factory FormationWithStats.fromJson(Map<String, dynamic> json) {
    return FormationWithStats(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      titre: json['titre']?.toString() ?? '',
      categorie: json['categorie']?.toString() ?? 'Général',
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      nbStagiaires: int.tryParse(json['nb_stagiaires']?.toString() ?? '0') ?? 0,
      nbVideos: int.tryParse(json['nb_videos']?.toString() ?? '0') ?? 0,
      dureeEstimee: int.tryParse(json['duree_estimee']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Model for Stagiaire in formation context
class StagiaireInFormation {
  final int id;
  final String prenom;
  final String nom;
  final String email;
  final String? avatar;
  final String? dateDebut;
  final String? dateFin;
  final int progress;
  final String status;

  StagiaireInFormation({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.email,
    this.avatar,
    this.dateDebut,
    this.dateFin,
    required this.progress,
    required this.status,
  });

  factory StagiaireInFormation.fromJson(Map<String, dynamic> json) {
    return StagiaireInFormation(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      prenom: json['prenom']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? json['image']?.toString(),
      dateDebut: json['date_debut']?.toString(),
      dateFin: json['date_fin']?.toString(),
      progress: int.tryParse(json['progress']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'inactive',
    );
  }

  String get fullName => '$prenom $nom';
  bool get isActive => status == 'active';
}

/// Model for unassigned stagiaire
class UnassignedStagiaire {
  final int id;
  final String prenom;
  final String nom;
  final String email;

  UnassignedStagiaire({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.email,
  });

  factory UnassignedStagiaire.fromJson(Map<String, dynamic> json) {
    return UnassignedStagiaire(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      prenom: json['prenom']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  String get fullName => '$prenom $nom';
}

/// Model for formation statistics
class FormationStats {
  final int totalStagiaires;
  final int completed;
  final int inProgress;
  final int notStarted;
  final double completionRate;

  FormationStats({
    required this.totalStagiaires,
    required this.completed,
    required this.inProgress,
    required this.notStarted,
    required this.completionRate,
  });

  factory FormationStats.fromJson(Map<String, dynamic> json) {
    return FormationStats(
      totalStagiaires:
          int.tryParse(json['total_stagiaires']?.toString() ?? '0') ?? 0,
      completed: int.tryParse(json['completed']?.toString() ?? '0') ?? 0,
      inProgress: int.tryParse(json['in_progress']?.toString() ?? '0') ?? 0,
      notStarted: int.tryParse(json['not_started']?.toString() ?? '0') ?? 0,
      completionRate:
          double.tryParse(json['completion_rate']?.toString() ?? '0') ?? 0.0,
    );
  }
}
