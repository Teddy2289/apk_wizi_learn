class Mission {
  final int id;
  final String title;
  final String description;
  final String type;
  final int goal;
  final String reward;
  final int progress;
  final bool completed;
  final String? completedAt;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.goal,
    required this.reward,
    required this.progress,
    required this.completed,
    this.completedAt,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      goal: json['goal'] ?? 1,
      reward: json['reward'] ?? '',
      progress: json['progress'] ?? 0,
      completed: json['completed'] ?? false,
      completedAt: json['completed_at'],
    );
  }
} 