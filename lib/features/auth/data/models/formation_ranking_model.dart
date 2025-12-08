class FormationRankingEntry {
  final int rang;
  final int stagiaireId;
  final String nom;
  final String prenom;
  final String? email;
  final String? avatarUrl;
  final int totalPoints;
  final int quizCompletes;
  final double moyennePoints;

  FormationRankingEntry({
    required this.rang,
    required this.stagiaireId,
    required this.nom,
    required this.prenom,
    this.email,
    this.avatarUrl,
    required this.totalPoints,
    required this.quizCompletes,
    required this.moyennePoints,
  });

  factory FormationRankingEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return FormationRankingEntry(
      rang: json['rang'] as int,
      stagiaireId: json['stagiaire_id'] as int,
      nom: user['nom'] as String,
      prenom: user['prenom'] as String,
      email: user['email'] as String?,
      avatarUrl: user['avatar'] as String?,
      totalPoints: json['total_points'] as int,
      quizCompletes: json['quiz_completes'] as int,
      moyennePoints: (json['moyenne_points'] as num).toDouble(),
    );
  }
}

class FormationRanking {
  final FormationInfo formation;
  final List<FormationRankingEntry> classement;
  final int totalParticipants;

  FormationRanking({
    required this.formation,
    required this.classement,
    required this.totalParticipants,
  });

  factory FormationRanking.fromJson(Map<String, dynamic> json) {
    final formationJson = json['formation'] as Map<String, dynamic>;
    final classementList = json['classement'] as List;

    return FormationRanking(
      formation: FormationInfo.fromJson(formationJson),
      classement: classementList
          .map((item) => FormationRankingEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalParticipants: json['total_participants'] as int,
    );
  }
}

class FormationInfo {
  final int id;
  final String titre;
  final String? description;
  final int totalQuiz;

  FormationInfo({
    required this.id,
    required this.titre,
    this.description,
    required this.totalQuiz,
  });

  factory FormationInfo.fromJson(Map<String, dynamic> json) {
    return FormationInfo(
      id: json['id'] as int,
      titre: json['titre'] as String,
      description: json['description'] as String?,
      totalQuiz: json['total_quiz'] as int,
    );
  }
}

class UserFormationRanking {
  final int formationId;
  final String formationTitre;
  final bool hasParticipation;
  final int? rang;
  final int? totalPoints;
  final int? quizCompletes;
  final int? totalQuiz;
  final int? totalParticipants;
  final double? pourcentageProgression;
  final String? message;

  UserFormationRanking({
    required this.formationId,
    required this.formationTitre,
    required this.hasParticipation,
    this.rang,
    this.totalPoints,
    this.quizCompletes,
    this.totalQuiz,
    this.totalParticipants,
    this.pourcentageProgression,
    this.message,
  });

  factory UserFormationRanking.fromJson(Map<String, dynamic> json) {
    return UserFormationRanking(
      formationId: json['formation_id'] as int,
      formationTitre: json['formation_titre'] as String,
      hasParticipation: json['has_participation'] as bool,
      rang: json['rang'] as int?,
      totalPoints: json['total_points'] as int?,
      quizCompletes: json['quiz_completes'] as int?,
      totalQuiz: json['total_quiz'] as int?,
      totalParticipants: json['total_participants'] as int?,
      pourcentageProgression: (json['pourcentage_progression'] as num?)?.toDouble(),
      message: json['message'] as String?,
    );
  }
}
