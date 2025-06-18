import 'package:equatable/equatable.dart';

class StagiaireInfo extends Equatable {
  final String id;
  final String prenom;
  final String? image;

  const StagiaireInfo({
    required this.id,
    required this.prenom,
    this.image,
  });

  @override
  List<Object?> get props => [id, prenom, image];
}

class Ranking extends Equatable {
  final StagiaireInfo stagiaire;
  final int totalPoints;
  final int quizCount;
  final double averageScore;
  final int rang;
  final int level;

  const Ranking({
    required this.stagiaire,
    required this.totalPoints,
    required this.quizCount,
    required this.averageScore,
    required this.rang,
    required this.level,
  });

  @override
  List<Object?> get props => [
        stagiaire,
        totalPoints,
        quizCount,
        averageScore,
        rang,
        level,
      ];
} 