import 'dart:convert';

class QuizSession {
  final String quizId;
  final String quizTitle;
  final List<String> questionIds;
  final Map<String, dynamic> answers;
  final int currentIndex;
  final int timeSpent;
  final DateTime lastUpdated;

  QuizSession({
    required this.quizId,
    required this.quizTitle,
    required this.questionIds,
    required this.answers,
    required this.currentIndex,
    required this.timeSpent,
    required this.lastUpdated,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'quizTitle': quizTitle,
      'questionIds': questionIds,
      'answers': answers,
      'currentIndex': currentIndex,
      'timeSpent': timeSpent,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Create from JSON
  factory QuizSession.fromJson(Map<String, dynamic> json) {
    return QuizSession(
      quizId: json['quizId'] as String,
      quizTitle: json['quizTitle'] as String,
      questionIds: List<String>.from(json['questionIds'] as List),
      answers: Map<String, dynamic>.from(json['answers'] as Map),
      currentIndex: json['currentIndex'] as int,
      timeSpent: json['timeSpent'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  // Calculate progress percentage
  int getProgressPercentage() {
    if (questionIds.isEmpty) return 0;
    return ((currentIndex / questionIds.length) * 100).round();
  }

  // Check if session is recent (less than 7 days old)
  bool isRecent() {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    return difference.inDays < 7;
  }

  @override
  String toString() {
    return 'QuizSession(quizId: $quizId, title: $quizTitle, progress: $currentIndex/${questionIds.length})';
  }
}
