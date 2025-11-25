import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/quiz_model.dart';

class ResumeQuizDialog extends StatelessWidget {
  final Map<String, dynamic> quizData;
  final VoidCallback onResume;
  final VoidCallback onDismiss;

  const ResumeQuizDialog({
    super.key,
    required this.quizData,
    required this.onResume,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Extract quiz information
    final quizId = quizData['quizId'] as String? ?? 'Unknown';
    final quizTitle = quizData['quizTitle'] as String? ?? 'Quiz';
    final questionIds = (quizData['questionIds'] as List<dynamic>?)?.cast<String>() ?? [];
    final currentIndex = quizData['currentIndex'] as int? ?? 0;
    final answers = quizData['answers'] as Map<String, dynamic>? ?? {};
    final timeSpent = quizData['timeSpent'] as int? ?? 0;
    final timestamp = quizData['timestamp'] as String? ?? 'Unknown';
    
    final questionCount = questionIds.length;
    final progress = questionCount > 0 
        ? ((currentIndex / questionCount) * 100).round() 
        : 0;

    return AlertDialog(
      backgroundColor: isDarkMode ? theme.cardColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.quiz_outlined,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Center(
              child: Text(
                'Quiz en cours',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Center(
              child: Text(
                'Vous avez un quiz non terminé :',
                style: TextStyle(
                  fontSize: 15,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),

            // Quiz Title
            Center(
              child: Text(
                quizTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // Progress
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Progression',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currentIndex / $questionCount questions ($progress%)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // DEBUG INFO -ExpandedDetails
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Détails de debug:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDebugRow('Quiz ID', quizId, isDarkMode),
                  _buildDebugRow('Timestamp', timestamp, isDarkMode),
                  _buildDebugRow('Temps écoulé', '${(timeSpent / 60).floor()}min ${timeSpent % 60}s', isDarkMode),
                  _buildDebugRow('Réponses sauvegardées', '${answers.length}', isDarkMode),
                  _buildDebugRow('IDs Questions', questionIds.take(3).join(', ') + (questionIds.length > 3 ? '...' : ''), isDarkMode),
                ],
              ), 
            ),
            const SizedBox(height: 16),

            // Question text
            Center(
              child: Text(
                'Voulez-vous reprendre où vous vous étiez arrêté ?',
                style: TextStyle(
                  fontSize: 15,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Dismiss button
        OutlinedButton(
          onPressed: onDismiss,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Text(
            'Ignorer',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Resume button
        ElevatedButton(
          onPressed: onResume,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Reprendre le quiz',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actionsAlignment: MainAxisAlignment.spaceBetween,
    );
  }

  Widget _buildDebugRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.white : Colors.black87,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
