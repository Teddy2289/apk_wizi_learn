import 'package:wizi_learn/core/utils/quiz_utils.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';
import 'package:wizi_learn/features/auth/data/models/quiz_model.dart';
import 'package:wizi_learn/features/auth/data/models/extended_formateur_model.dart';
import 'package:flutter/foundation.dart';

class QuizHistory {
  List<Question> get questions => quiz.questions;
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
      id: QuizUtils.cleanString(json['id'], fallback: '0'),
      quiz: Quiz.fromJson(json['quiz'] ?? {}),
      score: QuizUtils.cleanInt(json['score']),
      completedAt: QuizUtils.cleanString(json['completedAt']),
      timeSpent: QuizUtils.cleanInt(json['timeSpent']),
      totalQuestions: QuizUtils.cleanInt(json['totalQuestions']),
      correctAnswers: QuizUtils.cleanInt(json['correctAnswers']),
    );
  }
}

class GlobalRanking {
  final Stagiaire stagiaire;
  final List<ExtendedFormateur>
  formateurs; // ← Changez Formateur en ExtendedFormateur
  final int totalPoints;
  final int quizCount;
  final double averageScore;
  final int rang;

  GlobalRanking({
    required this.stagiaire,
    required this.formateurs,
    required this.totalPoints,
    required this.quizCount,
    required this.averageScore,
    required this.rang,
  });

  factory GlobalRanking.fromJson(Map<String, dynamic> json) {
    int safeInt(dynamic value, {int fallback = 0, String field = ''}) {
      if (value == null) return fallback;
      final parsed = int.tryParse(value.toString());
      if (parsed == null) {
        debugPrint('GlobalRanking: champ "$field" non convertible en int: $value');
        return fallback;
      }
      return parsed;
    }

    double safeDouble(dynamic value, {double fallback = 0, String field = ''}) {
      if (value == null) return fallback;
      final parsed = double.tryParse(value.toString());
      if (parsed == null) {
        debugPrint(
          'GlobalRanking: champ "$field" non convertible en double: $value',
        );
        return fallback;
      }
      return parsed;
    }

    return GlobalRanking(
      stagiaire: Stagiaire.fromJson(json['stagiaire'] ?? {}),
      formateurs:
          (json['formateurs'] as List? ?? [])
              .where((e) => e != null)
              .map((e) => ExtendedFormateur.fromJson(e)) // ← Changez ici
              .toList(),
      totalPoints: safeInt(json['totalPoints'], field: 'totalPoints'),
      quizCount: safeInt(json['quizCount'], field: 'quizCount'),
      averageScore: safeDouble(json['averageScore'], field: 'averageScore'),
      rang: safeInt(json['rang'], field: 'rang'),
    );
  }

  static GlobalRanking empty() {
    return GlobalRanking(
      stagiaire: Stagiaire(id: '0', prenom: 'Inconnu', nom: '', image: ''),
      formateurs: [],
      totalPoints: 0,
      quizCount: 0,
      averageScore: 0,
      rang: 0,
    );
  }
}

// ↓↓↓ SUPPRIMEZ la classe Formateur existante - elle est remplacée par ExtendedFormateur ↓↓↓
// class Formateur {
//   final String id;
//   final String prenom;
//   final String nom;
//   final String telephone;
//   final String? image;
//
//   Formateur({
//     required this.id,
//     required this.prenom,
//     required this.nom,
//     required this.telephone,
//     required this.image,
//   });
//
//   factory Formateur.fromJson(Map<String, dynamic> json) {
//     return Formateur(
//       id: QuizUtils.cleanString(json['id'], fallback: '0'),
//       prenom: QuizUtils.cleanString(json['prenom'], fallback: 'Formateur'),
//       nom: QuizUtils.cleanString(json['nom'], fallback: 'Inconnu'),
//       telephone: QuizUtils.cleanString(json['telephone'], fallback: ''),
//       image: QuizUtils.cleanString(json['image']),
//     );
//   }
// }

class Stagiaire {
  final String id;
  final String prenom;
  final String nom;
  final String image;

  Stagiaire({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.image,
  });

  factory Stagiaire.fromJson(Map<String, dynamic> json) {
    return Stagiaire(
      id: QuizUtils.cleanString(json['id'], fallback: '0'),
      prenom: QuizUtils.cleanString(json['prenom'], fallback: 'Inconnu'),
      nom: QuizUtils.cleanString(json['nom'], fallback: ''),
      image: QuizUtils.cleanString(json['image']),
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
    int safeInt(dynamic value, {int fallback = 0, String field = ''}) {
      if (value == null) return fallback;
      final parsed = int.tryParse(value.toString());
      if (parsed == null) {
        debugPrint('QuizStats: champ "$field" non convertible en int: $value');
        return fallback;
      }
      return parsed;
    }

    double safeDouble(dynamic value, {double fallback = 0, String field = ''}) {
      if (value == null) return fallback;
      final parsed = double.tryParse(value.toString());
      if (parsed == null) {
        debugPrint('QuizStats: champ "$field" non convertible en double: $value');
        return fallback;
      }
      return parsed;
    }

    return QuizStats(
      totalQuizzes: safeInt(json['totalQuizzes'], field: 'totalQuizzes'),
      averageScore: safeDouble(json['averageScore'], field: 'averageScore'),
      totalPoints: safeInt(json['totalPoints'], field: 'totalPoints'),
      categoryStats:
          (json['categoryStats'] as List? ?? [])
              .where((e) => e != null)
              .map((e) => CategoryStat.fromJson(e))
              .toList(),
      levelProgress: LevelProgress.fromJson(json['levelProgress'] ?? {}),
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
    int safeInt(dynamic value, {int fallback = 0, String field = ''}) {
      if (value == null) return fallback;
      final parsed = int.tryParse(value.toString());
      if (parsed == null) {
        debugPrint('CategoryStat: champ "$field" non convertible en int: $value');
        return fallback;
      }
      return parsed;
    }

    double safeDouble(dynamic value, {double fallback = 0, String field = ''}) {
      if (value == null) return fallback;
      final parsed = double.tryParse(value.toString());
      if (parsed == null) {
        debugPrint('CategoryStat: champ "$field" non convertible en double: $value');
        return fallback;
      }
      return parsed;
    }

    return CategoryStat(
      category: QuizUtils.cleanString(json['category'], fallback: 'Autre'),
      quizCount: safeInt(json['quizCount'], field: 'quizCount'),
      averageScore: safeDouble(json['averageScore'], field: 'averageScore'),
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
    int safeInt(dynamic value, {int fallback = 0, String field = ''}) {
      if (value == null) return fallback;
      final parsed = int.tryParse(value.toString());
      if (parsed == null) {
        debugPrint('LevelData: champ "$field" non convertible en int: $value');
        return fallback;
      }
      return parsed;
    }

    double? safeDouble(
      dynamic value, {
      double? fallback = 0,
      String field = '',
    }) {
      if (value == null) return fallback;
      final parsed = double.tryParse(value.toString());
      if (parsed == null) {
        debugPrint('LevelData: champ "$field" non convertible en double: $value');
        return fallback;
      }
      return parsed;
    }

    return LevelData(
      completed: safeInt(json['completed'], field: 'completed'),
      averageScore:
          json['averageScore'] != null
              ? safeDouble(json['averageScore'], field: 'averageScore')
              : null,
    );
  }
}
