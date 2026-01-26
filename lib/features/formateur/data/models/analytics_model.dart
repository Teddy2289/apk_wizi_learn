
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
      formations: _parseList(json['formations']),
      formateurs: _parseList(json['formateurs']),
    );
  }

  static List<dynamic> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map && data.containsKey('data')) {
      return data['data'] is List ? data['data'] : [];
    }
    return [];
  }
}

class InactiveStagiaire {
  final int id;
  final String prenom;
  final String nom;
  final String email;
  final String? avatar;
  final String? lastActivityAt;
  final double daysSinceActivity;
  final bool neverConnected;

  InactiveStagiaire({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.email,
    this.avatar,
    this.lastActivityAt,
    required this.daysSinceActivity,
    required this.neverConnected,
  });

  factory InactiveStagiaire.fromJson(Map<String, dynamic> json) {
    return InactiveStagiaire(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      prenom: json['prenom']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      lastActivityAt: json['last_activity_at']?.toString(),
      daysSinceActivity: double.tryParse(json['days_since_activity']?.toString() ?? '0') ?? 0.0,
      neverConnected: json['never_connected'] == true || json['never_connected'] == 1,
    );
  }
}

class OnlineStagiaire {
  final int id;
  final String prenom;
  final String nom;
  final String email;
  final String? avatar;
  final String lastActivityAt;
  final List<String> formations;

  OnlineStagiaire({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.email,
    this.avatar,
    required this.lastActivityAt,
    required this.formations,
  });

  factory OnlineStagiaire.fromJson(Map<String, dynamic> json) {
    return OnlineStagiaire(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      prenom: json['prenom']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      lastActivityAt: json['last_activity_at']?.toString() ?? 'À l\'instant',
      formations: (json['formations'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class StagiairePerformance {
  final int id;
  final String name;
  final String email;
  final String? image;
  final int totalQuizzes;
  final int totalLogins;
  final String? lastQuizAt;

  StagiairePerformance({
    required this.id,
    required this.name,
    required this.email,
    this.image,
    required this.totalQuizzes,
    required this.totalLogins,
    this.lastQuizAt,
  });

  factory StagiairePerformance.fromJson(Map<String, dynamic> json) {
    return StagiairePerformance(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Stagiaire',
      email: json['email']?.toString() ?? '',
      image: json['image']?.toString(),
      totalQuizzes: int.tryParse(json['total_quizzes']?.toString() ?? '0') ?? 0,
      totalLogins: int.tryParse(json['total_logins']?.toString() ?? '0') ?? 0,
      lastQuizAt: json['last_quiz_at']?.toString(),
    );
  }
}

class PerformanceRankings {
  final List<StagiairePerformance> mostQuizzes;
  final List<StagiairePerformance> mostActive;

  PerformanceRankings({
    required this.mostQuizzes,
    required this.mostActive,
  });

  factory PerformanceRankings.fromJson(Map<String, dynamic> json) {
    return PerformanceRankings(
      mostQuizzes: (json['most_quizzes'] as List?)
              ?.map((e) => StagiairePerformance.fromJson(e))
              .toList() ??
          [],
      mostActive: (json['most_active'] as List?)
              ?.map((e) => StagiairePerformance.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class FormationVideos {
  final int formationId;
  final String titre;
  final List<VideoBasicInfo> videos;

  FormationVideos({
    required this.formationId,
    required this.titre,
    required this.videos,
  });

  factory FormationVideos.fromJson(Map<String, dynamic> json) {
    return FormationVideos(
      formationId: int.tryParse(json['formation_id']?.toString() ?? '0') ?? 0,
      titre: json['formation_titre']?.toString() ?? '',
      videos: (json['videos'] as List?)
              ?.map((v) => VideoBasicInfo.fromJson(v))
              .toList() ??
          [],
    );
  }
}

class VideoBasicInfo {
  final int id;
  final String titre;
  final String? description;
  final String? url;
  final String? createdAt;

  VideoBasicInfo({
    required this.id,
    required this.titre,
    this.description,
    this.url,
    this.createdAt,
  });

  factory VideoBasicInfo.fromJson(Map<String, dynamic> json) {
    return VideoBasicInfo(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      titre: json['titre']?.toString() ?? '',
      description: json['description']?.toString(),
      url: json['url']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class VideoStats {
  final int videoId;
  final int totalViews;
  final double totalDurationWatched;
  final int completionRate;
  final List<StagiaireVideoStats> viewsByStagiaire;

  VideoStats({
    required this.videoId,
    required this.totalViews,
    required this.totalDurationWatched,
    required this.completionRate,
    required this.viewsByStagiaire,
  });

  factory VideoStats.fromJson(Map<String, dynamic> json) {
    return VideoStats(
      videoId: int.tryParse(json['video_id']?.toString() ?? '0') ?? 0,
      totalViews: int.tryParse(json['total_views']?.toString() ?? '0') ?? 0,
      totalDurationWatched: double.tryParse(json['total_duration_watched']?.toString() ?? '0') ?? 0.0,
      completionRate: int.tryParse(json['completion_rate']?.toString() ?? '0') ?? 0,
      viewsByStagiaire: (json['views_by_stagiaire'] as List?)
              ?.map((v) => StagiaireVideoStats.fromJson(v))
              .toList() ??
          [],
    );
  }
}

class StagiaireVideoStats {
  final int id;
  final String prenom;
  final String nom;
  final bool completed;
  final double totalWatched;
  final int percentage;

  StagiaireVideoStats({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.completed,
    required this.totalWatched,
    required this.percentage,
  });

  factory StagiaireVideoStats.fromJson(Map<String, dynamic> json) {
    return StagiaireVideoStats(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      prenom: json['prenom']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      completed: json['completed'] == true || json['completed'] == 1,
      totalWatched: double.tryParse(json['total_watched']?.toString() ?? '0') ?? 0.0,
      percentage: int.tryParse(json['percentage']?.toString() ?? '0') ?? 0,
    );
  }
}

class DemandeSuivi {
  final int id;
  final String date;
  final String statut;
  final String formation;
  final String stagiaireName;
  final int stagiaireId;
  final String? motif;

  DemandeSuivi({
    required this.id,
    required this.date,
    required this.statut,
    required this.formation,
    required this.stagiaireName,
    required this.stagiaireId,
    this.motif,
  });

  factory DemandeSuivi.fromJson(Map<String, dynamic> json) {
    final stagiaire = json['stagiaire'];
    final name = stagiaire != null ? "${stagiaire['prenom'] ?? ''} ${stagiaire['name'] ?? ''}".trim() : 'Stagiaire';
    final sId = stagiaire != null ? int.tryParse(stagiaire['id']?.toString() ?? '0') ?? 0 : 0;
    
    return DemandeSuivi(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      date: json['date']?.toString() ?? '',
      statut: json['statut']?.toString() ?? 'en_attente',
      formation: json['formation']?.toString() ?? 'Formation',
      stagiaireName: name.isNotEmpty ? name : 'Stagiaire',
      stagiaireId: sId,
      motif: json['motif']?.toString(),
    );
  }
}

class ParrainageSuivi {
  final int id;
  final String date;
  final int points;
  final String gains;
  final String? parrainName;
  final String filleulName;
  final String filleulStatut;

  ParrainageSuivi({
    required this.id,
    required this.date,
    required this.points,
    required this.gains,
    this.parrainName,
    required this.filleulName,
    required this.filleulStatut,
  });

  factory ParrainageSuivi.fromJson(Map<String, dynamic> json) {
    final parrain = json['parrain'];
    final filleul = json['filleul'];
    
    final pName = parrain != null ? parrain['name']?.toString() : null;
    final fName = filleul != null ? "${filleul['prenom'] ?? ''} ${filleul['name'] ?? ''}".trim() : 'Filleul';

    return ParrainageSuivi(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      date: json['date']?.toString() ?? '',
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      gains: json['gains']?.toString() ?? '0',
      parrainName: pName,
      filleulName: fName.isNotEmpty ? fName : 'Filleul',
      filleulStatut: filleul != null ? filleul['statut']?.toString() ?? 'actif' : 'actif',
    );
  }
}
