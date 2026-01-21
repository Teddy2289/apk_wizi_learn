
/// Simple analytics models for trainers
library;

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
  final int totalFormations;
  final int totalQuizzesTaken;
  final int activeThisWeek;
  final int inactiveCount;
  final int neverConnected;
  final double avgQuizScore;
  final double totalVideoHours;
  final List<dynamic> formations; // Keeping dynamic for now to avoid circular deps or complex nested models immediately
  final List<dynamic> formateurs; // Keeping dynamic for now

  DashboardSummary({
    required this.totalStagiaires,
    required this.totalFormations,
    required this.totalQuizzesTaken,
    required this.activeThisWeek,
    required this.inactiveCount,
    required this.neverConnected,
    required this.avgQuizScore,
    required this.totalVideoHours,
    required this.formations,
    required this.formateurs,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalStagiaires: int.tryParse(json['total_stagiaires']?.toString() ?? '0') ?? 0,
      totalFormations: int.tryParse(json['total_formations']?.toString() ?? '0') ?? 0,
      totalQuizzesTaken: int.tryParse(json['total_quizzes_taken']?.toString() ?? '0') ?? 0,
      activeThisWeek: int.tryParse(json['active_this_week']?.toString() ?? '0') ?? 0,
      inactiveCount: int.tryParse(json['inactive_count']?.toString() ?? '0') ?? 0,
      neverConnected: int.tryParse(json['never_connected']?.toString() ?? '0') ?? 0,
      avgQuizScore: double.tryParse(json['avg_quiz_score']?.toString() ?? '0') ?? 0.0,
      totalVideoHours: double.tryParse(json['total_video_hours']?.toString() ?? '0') ?? 0.0,
      formations: json['formations'] as List<dynamic>? ?? [],
      formateurs: json['formateurs'] as List<dynamic>? ?? [],
    );
  }
}
