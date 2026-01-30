import 'package:equatable/equatable.dart';

class ArenaFormateur extends Equatable {
  final int id;
  final String prenom;
  final String nom;
  final String? image;
  final int totalStagiaires;
  final int totalPoints;
  final List<ArenaStagiaire> stagiaires;

  const ArenaFormateur({
    required this.id,
    required this.prenom,
    required this.nom,
    this.image,
    required this.totalStagiaires,
    required this.totalPoints,
    required this.stagiaires,
  });

  factory ArenaFormateur.fromJson(Map<String, dynamic> json) {
    return ArenaFormateur(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      prenom: json['prenom']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      image: json['image']?.toString(),
      totalStagiaires: int.tryParse(json['total_stagiaires']?.toString() ?? '0') ?? 0,
      totalPoints: int.tryParse(json['total_points']?.toString() ?? '0') ?? 0,
      stagiaires: (json['stagiaires'] as List?)
          ?.map((e) => ArenaStagiaire.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [id, prenom, nom, image, totalStagiaires, totalPoints, stagiaires];
}

class ArenaStagiaire extends Equatable {
  final int id;
  final String prenom;
  final String nom;
  final String? image;
  final int points;

  const ArenaStagiaire({
    required this.id,
    required this.prenom,
    required this.nom,
    this.image,
    required this.points,
  });

  factory ArenaStagiaire.fromJson(Map<String, dynamic> json) {
    return ArenaStagiaire(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      prenom: json['prenom']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      image: json['image']?.toString(),
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, prenom, nom, image, points];
}
