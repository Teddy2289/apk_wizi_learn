class Achievement {
  final int id;
  final String name;
  final String type;
  final int condition;
  final String description;
  final String? icon;
  final String? level;
  final int? quizId;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.type,
    required this.condition,
    required this.description,
    this.icon,
    this.level,
    this.quizId,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      condition: json['condition'] is int ? json['condition'] : int.tryParse(json['condition'].toString()) ?? 0,
      description: json['description'] ?? '',
      icon: json['icon'],
      level: json['level'],
      quizId: json['quiz_id'] is int ? json['quiz_id'] : int.tryParse(json['quiz_id']?.toString() ?? ''),
      unlockedAt: json['pivot'] != null && json['pivot']['unlocked_at'] != null
          ? DateTime.tryParse(json['pivot']['unlocked_at'])
          : null,
    );
  }
} 