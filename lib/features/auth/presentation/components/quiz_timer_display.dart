import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/quiz_session/quiz_session_manager.dart';

class QuizTimerDisplay extends StatelessWidget {
  final QuizSessionManager sessionManager;

  const QuizTimerDisplay({super.key, required this.sessionManager});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: sessionManager.remainingSeconds,
      builder: (_, seconds, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Temps restant: $seconds secondes',
            style: const TextStyle(fontSize: 16),
          ),
        );
      },
    );
  }
}
