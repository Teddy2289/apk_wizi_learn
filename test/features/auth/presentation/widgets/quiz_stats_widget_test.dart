import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/quiz_stats_widget.dart';
import 'package:wizi_learn/features/auth/data/models/stats_model.dart';

void main() {
  testWidgets('QuizStatsWidget se construit sans erreur', (
    WidgetTester tester,
  ) async {
    final stats = QuizStats(
      totalQuizzes: 0,
      averageScore: 0.0,
      totalPoints: 0,
      categoryStats: [],
      levelProgress: LevelProgress(
        debutant: LevelData(completed: 0, averageScore: 0.00),
        intermediaire: LevelData(completed: 0, averageScore: 0.00),
        avance: LevelData(completed: 0, averageScore: 0.00),
      ),
    );
    await tester.pumpWidget(MaterialApp(home: QuizStatsWidget(stats: stats)));
    expect(find.byType(QuizStatsWidget), findsOneWidget);
  });
}
