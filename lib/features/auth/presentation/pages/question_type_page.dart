import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/question_types/audio_question.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/question_types/fill_blank.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/question_types/flashcard.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/question_types/matching.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/question_types/multiple_choice.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/question_types/ordering.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/question_types/true_false.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/question_types/word_bank.dart';

class QuestionTypePage extends StatelessWidget {
  final Question question;
  final Function(dynamic) onAnswer;
  final bool showFeedback;
  final VoidCallback? onNext;

  const QuestionTypePage({
    super.key,
    required this.question,
    required this.onAnswer,
    this.showFeedback = false,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth > 600 ? 24 : 16, // Responsive padding
        vertical: 12,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question Card
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        question.type.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Question Text (if not fill in blank)
                    // if (!isFillBlank)
                    //   Text(
                    //     question.text,
                    //     style: theme.textTheme.titleMedium?.copyWith(
                    //       fontWeight: FontWeight.w600,
                    //       fontSize: 16, // Reduced font size
                    //     ),
                    //   ),
                    const SizedBox(height: 16),

                    // Question Content
                    _buildQuestionByType(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Explanation (if showing feedback)
            if (showFeedback && question.explication != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  key: ValueKey(showFeedback),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 20,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Explication",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.explication!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionByType() {
    switch (question.type) {
      case "choix multiples":
        return MultipleChoiceQuestion(
          question: question,
          onAnswer: (answers) => onAnswer(answers),
          onNext: onNext,
        );
      case "vrai/faux":
        return TrueFalseQuestion(
          question: question,
          onAnswer: (answers) => onAnswer(answers),
          showFeedback: showFeedback,
        );
      case "remplir le champ vide":
        return FillBlankQuestion(
          question: question,
          onAnswer: onAnswer,
          showFeedback: showFeedback,
          onTimeout: () {},
        );
      case "rearrangement":
        return OrderingQuestion(
          question: question,
          onAnswer: onAnswer,
          showFeedback: showFeedback,
        );
      case "banque de mots":
        return WordBankQuestion(
          question: question,
          onAnswer: onAnswer,
          showFeedback: showFeedback,
        );
      case "correspondance":
        return MatchingQuestion(
          question: question,
          onAnswer: onAnswer,
          showFeedback: showFeedback,
        );
      case "carte flash":
        return FlashcardQuestion(
          question: question,
          onAnswer: onAnswer,
          showFeedback: showFeedback,
        );
      case "question audio":
        return AudioQuestion(
          question: question,
          onAnswer: onAnswer,
          showFeedback: showFeedback,
        );
      default:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, size: 20, color: Colors.red[800]),
                  const SizedBox(width: 8),
                  Text(
                    "Type non supporté",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Type: ${question.type}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        );
    }
  }
}