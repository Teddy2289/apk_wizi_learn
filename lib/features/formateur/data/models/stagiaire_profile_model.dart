
/// Model representing detailed student profile data
class StagiaireProfile {
  final StagiaireInfo stagiaire;
  final StagiaireStats stats;
  final StagiaireActivity activity;
  final List<FormationProgress> formations;
  final List<QuizResult> quizHistory;
  final Contacts? contacts;
  final List<LoginHistoryEntry> loginHistory;
  final VideoStats? videoStats;

  StagiaireProfile({
    required this.stagiaire,
    required this.stats,
    required this.activity,
    required this.formations,
    required this.quizHistory,
    this.contacts,
    required this.loginHistory,
    this.videoStats,
  });

  factory StagiaireProfile.fromJson(Map<String, dynamic> json) {
    return StagiaireProfile(
      stagiaire: StagiaireInfo.fromJson(json['stagiaire'] ?? {}),
      stats: StagiaireStats.fromJson(json['stats'] ?? {}),
      activity: StagiaireActivity.fromJson(json['activity'] ?? {}),
      formations: (json['formations'] as List?)
              ?.map((f) => FormationProgress.fromJson(f))
              .toList() ??
          [],
      quizHistory: (json['quiz_history'] as List?)
              ?.map((q) => QuizResult.fromJson(q))
              .toList() ??
          [],
      contacts: json['contacts'] != null
          ? Contacts.fromJson(json['contacts'])
          : null,
      loginHistory: (json['login_history'] as List?)
              ?.map((l) => LoginHistoryEntry.fromJson(l))
              .toList() ??
          [],
      videoStats: json['video_stats'] != null
          ? VideoStats.fromJson(json['video_stats'])
          : null,
    );
  }
}

/// Contact person information
class ContactInfo {
  final int id;
  final String nom;
  final String prenom;
  final String? telephone;
  final String? email;
  final String? image;
  final String? civilite;

  ContactInfo({
    required this.id,
    required this.nom,
    required this.prenom,
    this.telephone,
    this.email,
    this.image,
    this.civilite,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nom: json['nom']?.toString() ?? '',
      prenom: json['prenom']?.toString() ?? '',
      telephone: json['telephone']?.toString(),
      email: json['email']?.toString(),
      image: json['image']?.toString(),
      civilite: json['civilite']?.toString(),
    );
  }

  String get fullName => '$prenom $nom';
}

/// Contacts grouping (formateurs, pole_relation, commercials)
class Contacts {
  final List<ContactInfo> formateurs;
  final List<ContactInfo> poleRelation;
  final List<ContactInfo> commercials;
  final ContactInfo? partenaire;

  Contacts({
    required this.formateurs,
    required this.poleRelation,
    required this.commercials,
    this.partenaire,
  });

  factory Contacts.fromJson(Map<String, dynamic> json) {
    return Contacts(
      formateurs: (json['formateurs'] as List?)
              ?.map((f) => ContactInfo.fromJson(f))
              .toList() ??
          [],
      poleRelation: (json['pole_relation'] as List?)
              ?.map((p) => ContactInfo.fromJson(p))
              .toList() ??
          [],
      commercials: (json['commercials'] as List?)
              ?.map((c) => ContactInfo.fromJson(c))
              .toList() ??
          [],
      partenaire: json['partenaire'] != null
          ? ContactInfo.fromJson(json['partenaire'])
          : null,
    );
  }

  bool get hasAny => formateurs.isNotEmpty || poleRelation.isNotEmpty || commercials.isNotEmpty || partenaire != null;
}

/// Login history entry
class LoginHistoryEntry {
  final int id;
  final String ipAddress;
  final String device;
  final String browser;
  final String platform;
  final String loginAt;

  LoginHistoryEntry({
    required this.id,
    required this.ipAddress,
    required this.device,
    required this.browser,
    required this.platform,
    required this.loginAt,
  });

  factory LoginHistoryEntry.fromJson(Map<String, dynamic> json) {
    return LoginHistoryEntry(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      ipAddress: json['ip_address']?.toString() ?? '',
      device: json['device']?.toString() ?? '',
      browser: json['browser']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      loginAt: json['login_at']?.toString() ?? '',
    );
  }
}

/// Video watching stats
class VideoStats {
  final int totalWatched;
  final int totalTimeWatched;

  VideoStats({
    required this.totalWatched,
    required this.totalTimeWatched,
  });

  factory VideoStats.fromJson(Map<String, dynamic> json) {
    return VideoStats(
      totalWatched: int.tryParse(json['total_watched']?.toString() ?? '0') ?? 0,
      totalTimeWatched: int.tryParse(json['total_time_watched']?.toString() ?? '0') ?? 0,
    );
  }
}


class StagiaireInfo {
  final int id;
  final String prenom;
  final String nom;
  final String email;
  final String? telephone;
  final String? image;
  final String createdAt;
  final String? dateInscription;
  final String? dateDebutFormation;
  final String? lastLogin;

  StagiaireInfo({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.email,
    this.telephone,
    this.image,
    required this.createdAt,
    this.dateInscription,
    this.dateDebutFormation,
    this.lastLogin,
  });

  factory StagiaireInfo.fromJson(Map<String, dynamic> json) {
    return StagiaireInfo(
      id: int.tryParse(json['id'].toString()) ?? 0,
      prenom: json['prenom']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      telephone: json['telephone']?.toString(),
      image: json['image']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      dateInscription: json['date_inscription']?.toString(),
      dateDebutFormation: json['date_debut_formation']?.toString(),
      lastLogin: json['last_login']?.toString(),
    );
  }

  String get fullName => '$prenom $nom';
}

class StagiaireStats {
  final int totalPoints;
  final String currentBadge;
  final int formationsCompleted;
  final int formationsInProgress;
  final int quizzesCompleted;
  final double averageScore;
  final int totalTimeMinutes;
  final int loginStreak;

  StagiaireStats({
    required this.totalPoints,
    required this.currentBadge,
    required this.formationsCompleted,
    required this.formationsInProgress,
    required this.quizzesCompleted,
    required this.averageScore,
    required this.totalTimeMinutes,
    required this.loginStreak,
  });

  factory StagiaireStats.fromJson(Map<String, dynamic> json) {
    return StagiaireStats(
      totalPoints: int.tryParse(json['total_points']?.toString() ?? '0') ?? 0,
      currentBadge: json['current_badge']?.toString() ?? 'Aucun',
      formationsCompleted:
          int.tryParse(json['formations_completed']?.toString() ?? '0') ?? 0,
      formationsInProgress:
          int.tryParse(json['formations_in_progress']?.toString() ?? '0') ?? 0,
      quizzesCompleted:
          int.tryParse(json['quizzes_completed']?.toString() ?? '0') ?? 0,
      averageScore:
          double.tryParse(json['average_score']?.toString() ?? '0') ?? 0.0,
      totalTimeMinutes:
          int.tryParse(json['total_time_minutes']?.toString() ?? '0') ?? 0,
      loginStreak: int.tryParse(json['login_streak']?.toString() ?? '0') ?? 0,
    );
  }
}

class StagiaireActivity {
  final List<DayActivity> last30Days;
  final List<RecentActivity> recentActivities;

  StagiaireActivity({
    required this.last30Days,
    required this.recentActivities,
  });

  factory StagiaireActivity.fromJson(Map<String, dynamic> json) {
    return StagiaireActivity(
      last30Days: (json['last_30_days'] as List?)
              ?.map((d) => DayActivity.fromJson(d))
              .toList() ??
          [],
      recentActivities: (json['recent_activities'] as List?)
              ?.map((a) => RecentActivity.fromJson(a))
              .toList() ??
          [],
    );
  }
}

class DayActivity {
  final String date;
  final int actions;

  DayActivity({required this.date, required this.actions});

  factory DayActivity.fromJson(Map<String, dynamic> json) {
    return DayActivity(
      date: json['date']?.toString() ?? '',
      actions: int.tryParse(json['actions']?.toString() ?? '0') ?? 0,
    );
  }
}

class RecentActivity {
  final String type;
  final String title;
  final int? score;
  final String timestamp;

  RecentActivity({
    required this.type,
    required this.title,
    this.score,
    required this.timestamp,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      score: json['score'] != null
          ? int.tryParse(json['score'].toString())
          : null,
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }
}

class FormationProgress {
  final int id;
  final String title;
  final String category;
  final String? startedAt;
  final String? completedAt;
  final int progress;
  final List<FormationLevel>? levels;

  FormationProgress({
    required this.id,
    required this.title,
    required this.category,
    this.startedAt,
    this.completedAt,
    required this.progress,
    this.levels,
  });

  factory FormationProgress.fromJson(Map<String, dynamic> json) {
    return FormationProgress(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      startedAt: json['started_at']?.toString(),
      completedAt: json['completed_at']?.toString(),
      progress: int.tryParse(json['progress']?.toString() ?? '0') ?? 0,
      levels: (json['levels'] as List?)
          ?.map((l) => FormationLevel.fromJson(l))
          .toList(),
    );
  }

  bool get isCompleted => completedAt != null;
  bool get isInProgress => startedAt != null && completedAt == null;
}

class QuizResult {
  final int quizId;
  final String title;
  final String category;
  final int score;
  final int maxScore;
  final String completedAt;
  final int timeSpent;

  QuizResult({
    required this.quizId,
    required this.title,
    required this.category,
    required this.score,
    required this.maxScore,
    required this.completedAt,
    required this.timeSpent,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      quizId: int.tryParse(json['quiz_id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      score: int.tryParse(json['score']?.toString() ?? '0') ?? 0,
      maxScore: int.tryParse(json['max_score']?.toString() ?? '100') ?? 100,
      completedAt: json['completed_at']?.toString() ?? '',
      timeSpent: int.tryParse(json['time_spent']?.toString() ?? '0') ?? 0,
    );
  }

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;
}

class FormationLevel {
  final String name;
  final double avgScore;
  final int bestScore;
  final int completions;

  FormationLevel({
    required this.name,
    required this.avgScore,
    required this.bestScore,
    required this.completions,
  });

  factory FormationLevel.fromJson(Map<String, dynamic> json) {
    return FormationLevel(
      name: json['name']?.toString() ?? 'Inconnu',
      avgScore: double.tryParse(json['avg_score']?.toString() ?? '0') ?? 0.0,
      bestScore: int.tryParse(json['best_score']?.toString() ?? '0') ?? 0,
      completions: int.tryParse(json['completions']?.toString() ?? '0') ?? 0,
    );
  }
}
