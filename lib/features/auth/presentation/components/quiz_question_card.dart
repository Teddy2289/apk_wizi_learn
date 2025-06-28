  import 'package:flutter/material.dart';
  import 'package:wizi_learn/features/auth/data/models/question_model.dart';
  import 'quiz_answer_row.dart';
  import 'quiz_matching_details.dart';

  class QuizQuestionCard extends StatelessWidget {
    final Question question;
    final bool isCorrect;
    final int index;

    const QuizQuestionCard({
      super.key,
      required this.question,
      required this.isCorrect,
      required this.index,
    });

    @override
    Widget build(BuildContext context) {
      return Card(
        color: isCorrect ? Colors.green[50] : Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question ${index + 1}: ${question.text}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              QuizAnswerRow(
                title: "Votre réponse:",
                answer: _formatUserAnswer(question),
                isCorrect: isCorrect,
              ),
              QuizAnswerRow(
                title: "Réponse correcte:",
                answer: _formatCorrectAnswer(question),
                isCorrect: true,
              ),

              if (question.type == "correspondance")
                QuizMatchingDetails(question: question),
            ],
          ),
        ),
      );
    }

    String _formatCorrectAnswer(Question question) {
      if (question.meta?.correctAnswers != null) {
        return _formatAnswer(question.meta!.correctAnswers);
      }

      if (question.correctAnswers != null) {
        return _formatAnswer(question.correctAnswers);
      }
      return question.correctAnswersList.map((a) => a.text).join(", ");
    }

    String _formatUserAnswer(Question question) {
      if (question.meta?.selectedAnswers != null) {
        return _formatAnswer(question.meta!.selectedAnswers);
      }

      debugPrint("selectedAnswers for ${question.id}: ${question.selectedAnswers}");

      // Cas particulier pour les choix multiples
      if (question.type == "choix multiples") {
        // Vérifier explicitement si selectedAnswers est null
        if (question.selectedAnswers == null) {
          return "Non répondue";
        }

        // Si c'est une liste vide, l'utilisateur a explicitement soumis une réponse vide
        if (question.selectedAnswers.isEmpty) {
          return "Aucune réponse sélectionnée";
        }

        // Si selectedAnswers contient déjà des textes
        if (question.selectedAnswers.first is String) {
          return question.selectedAnswers.join(", ");
        }

        // Si selectedAnswers contient des objets avec id/text
        if (question.selectedAnswers.first is Map) {
          return question.selectedAnswers.map((a) => a['text'] ?? a['id'].toString()).join(", ");
        }
      }

      return _formatAnswer(question.selectedAnswers);
    }

    String _formatAnswer(dynamic answer) {
      if (answer == null) return "Non répondue";
      if (answer is Map) return answer.entries.map((e) => "${e.key} → ${e.value}").join(", ");
      if (answer is List) return answer.join(", ");
      return answer.toString();
    }
  }