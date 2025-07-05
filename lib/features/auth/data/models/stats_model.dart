class QuizHistory {
  final String id;
  final Quiz quiz;
  final int score;
  final String completedAt;
  final int timeSpent;
  final int totalQuestions;
  final int correctAnswers;

  QuizHistory({
    required this.id,
    required this.quiz,
    required this.score,
    required this.completedAt,
    required this.timeSpent,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  factory QuizHistory.fromJson(Map<String, dynamic> json) {
    return QuizHistory(
      id: json['id'].toString(),
      quiz: Quiz.fromJson(json['quiz']),
      score: json['score'],
      completedAt: json['completedAt'],
      timeSpent: json['timeSpent'],
      totalQuestions: json['totalQuestions'],
      correctAnswers: json['correctAnswers'],
    );
  }
}

class Quiz {
  final String id;
  final String title;
  final String category;
  final String level;

  Quiz({
    required this.id,
    required this.title,
    required this.category,
    required this.level,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'].toString(),
      title: json['title'],
      category: json['category'],
      level: json['level'],
    );
  }
}

class GlobalRanking {
  final Stagiaire stagiaire;
  final int totalPoints;
  final int quizCount;
  final double averageScore;
  final int rang;

  GlobalRanking({
    required this.stagiaire,
    required this.totalPoints,
    required this.quizCount,
    required this.averageScore,
    required this.rang,
  });

  factory GlobalRanking.fromJson(Map<String, dynamic> json) {
    return GlobalRanking(
      stagiaire: Stagiaire.fromJson(json['stagiaire'] ?? {}), // Gestion du null
      totalPoints: json['totalPoints'] as int? ?? 0,
      quizCount: json['quizCount'] as int? ?? 0,
      averageScore: (json['averageScore'] is int)
          ? (json['averageScore'] as int).toDouble()
          : json['averageScore'] as double? ?? 0.0,
      rang: json['rang'] as int? ?? 0,
    );
  }

  static GlobalRanking empty() {
    return GlobalRanking(
      stagiaire: Stagiaire(id: '0', prenom: 'Inconnu', image: ''),
      totalPoints: 0,
      quizCount: 0,
      averageScore: 0,
      rang: 0,
    );
  }
}
class Stagiaire {
  final String id;
  final String prenom;
  final String image;

  Stagiaire({
    required this.id,
    required this.prenom,
    required this.image,
  });

  factory Stagiaire.fromJson(Map<String, dynamic> json) {
    return Stagiaire(
      id: json['id']?.toString() ?? '0', // Gestion du null
      prenom: json['prenom']?.toString() ?? 'Inconnu', // Gestion du null
      image: json['image']?.toString() ?? '', // Gestion du null
    );
  }
}
class QuizStats {
  final int totalQuizzes;
  final double averageScore;
  final int totalPoints;
  final List<CategoryStat> categoryStats;
  final LevelProgress levelProgress;

  QuizStats({
    required this.totalQuizzes,
    required this.averageScore,
    required this.totalPoints,
    required this.categoryStats,
    required this.levelProgress,
  });

  factory QuizStats.fromJson(Map<String, dynamic> json) {
    return QuizStats(
      totalQuizzes: json['totalQuizzes'],
      averageScore: double.parse(json['averageScore'].toString()),
      totalPoints: int.parse(json['totalPoints'].toString()),
      categoryStats:
          (json['categoryStats'] as List)
              .map((e) => CategoryStat.fromJson(e))
              .toList(),
      levelProgress: LevelProgress.fromJson(json['levelProgress']),
    );
  }
}

class CategoryStat {
  final String category;
  final int quizCount;
  final double averageScore;

  CategoryStat({
    required this.category,
    required this.quizCount,
    required this.averageScore,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      category: json['category'],
      quizCount: json['quizCount'],
      averageScore:
          (json['averageScore'] is int)
              ? (json['averageScore'] as int).toDouble()
              : json['averageScore'],
    );
  }
}

class LevelProgress {
  final LevelData debutant;
  final LevelData intermediaire;
  final LevelData avance;

  LevelProgress({
    required this.debutant,
    required this.intermediaire,
    required this.avance,
  });

  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      debutant: LevelData.fromJson(json['débutant']),
      intermediaire: LevelData.fromJson(json['intermédiaire']),
      avance: LevelData.fromJson(json['avancé']),
    );
  }
}

class LevelData {
  final int completed;
  final double? averageScore;

  LevelData({required this.completed, required this.averageScore});

  factory LevelData.fromJson(Map<String, dynamic> json) {
    return LevelData(
      completed: json['completed'],
      averageScore:
          (json['averageScore'] is int)
              ? (json['averageScore'] as int).toDouble()
              : json['averageScore'],
    );
  }
}
