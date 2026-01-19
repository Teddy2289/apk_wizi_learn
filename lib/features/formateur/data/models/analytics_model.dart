import 'package:flutter/foundation.dart';

/// Simple analytics models for trainers

class QuizSuccessStats {
  final String quizName;
  final String category;
  final int totalAttempts;
  final int successfulAttempts;
  final double successRate;
  final double averageScore;

  QuizSuccessStats({
    required this.quizName,
    required this.category,
    required this.totalAttempts,
    required this.successfulAttempts,
    required this.successRate,
    required this.averageScore,
  });

  factory QuizSuccessStats.fromJson(Map<String, dynamic> json) {
    return QuizSuccessStats(
      quizName: json['quiz_name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Général',
      totalAttempts: int.tryParse(json['total_attempts']?.toString() ?? '0') ?? 0,
      successfulAttempts: int.tryParse(json['successful_attempts']?.toString() ?? '0') ?? 0,
      successRate: double.tryParse(json['success_rate']?.toString() ?? '0') ?? 0.0,
      averageScore: double.tryParse(json['average_score']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class CompletionTrend {
  final String date;
  final double avgTimeMinutes;
  final int quizCount;

  CompletionTrend({
    required this.date,
    required this.avgTimeMinutes,
    required this.quizCount,
  });

  factory CompletionTrend.fromJson(Map<String, dynamic> json) {
    return CompletionTrend(
      date: json['date']?.toString() ?? '',
      avgTimeMinutes: double.tryParse(json['avg_time_minutes']?.toString() ?? '0') ?? 0.0,
      quizCount: int.tryParse(json['quiz_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class ActivityByDay {
  final String day;
  final int activityCount;

  ActivityByDay({required this.day, required this.activityCount});

  factory ActivityByDay.fromJson(Map<String, dynamic> json) {
    return ActivityByDay(
      day: json['day']?.toString() ?? '',
      activityCount: int.tryParse(json['activity_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class DropoutStats {
  final String quizName;
  final String category;
  final int totalAttempts;
  final int completed;
  final int abandoned;
  final double dropoutRate;

  DropoutStats({
    required this.quizName,
    required this.category,
    required this.totalAttempts,
    required this.completed,
    required this.abandoned,
    required this.dropoutRate,
  });

  factory DropoutStats.fromJson(Map<String, dynamic> json) {
    return DropoutStats(
      quizName: json['quiz_name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Général',
      totalAttempts: int.tryParse(json['total_attempts']?.toString() ?? '0') ?? 0,
      completed: int.tryParse(json['completed']?.toString() ?? '0') ?? 0,
      abandoned: int.tryParse(json['abandoned']?.toString() ?? '0') ?? 0,
      dropoutRate: double.tryParse(json['dropout_rate']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class DashboardSummary {
  final int totalStagiaires;
  final int activeStagiaires;
  final int totalCompletions;
  final double averageScore;
  final double trendPercentage;

  DashboardSummary({
    required this.totalStagiaires,
    required this.activeStagiaires,
    required this.totalCompletions,
    required this.averageScore,
    required this.trendPercentage,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalStagiaires: int.tryParse(json['total_stagiaires']?.toString() ?? '0') ?? 0,
      activeStagiaires: int.tryParse(json['active_stagiaires']?.toString() ?? '0') ?? 0,
      totalCompletions: int.tryParse(json['total_completions']?.toString() ?? '0') ?? 0,
      averageScore: double.tryParse(json['average_score']?.toString() ?? '0') ?? 0.0,
      trendPercentage: double.tryParse(json['trend_percentage']?.toString() ?? '0') ?? 0.0,
    );
  }
}
