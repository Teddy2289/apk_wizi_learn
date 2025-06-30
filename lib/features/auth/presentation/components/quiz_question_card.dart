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
      debugPrint("QUESTION REPONSE====${question.meta?.selectedAnswers}");
      debugPrint("Formatting answer for question ${question.id} of type ${question.type}");
      debugPrint("Selected answers raw: ${question.selectedAnswers}");

      // 1. Vérifier d'abord les métadonnées
      if (question.meta?.selectedAnswers != null) {
        return _formatAnswer(question.meta!.selectedAnswers);
      }

      // 2. Cas spécial pour les questions audio
      if (question.type == "question audio") {
        if (question.selectedAnswers == null) {
          return "Non répondue";
        }

        // Le serveur peut renvoyer soit un Map, soit une String directe
        if (question.selectedAnswers is Map) {
          return question.selectedAnswers['text'] ?? "Réponse audio";
        }

        if (question.selectedAnswers is String) {
          return question.selectedAnswers;
        }

        // Cas par défaut
        return question.selectedAnswers.toString();
      }

      // 3. Pour les choix multiples
      if (question.type == "choix multiples" || question.type == "rearrangement") {
        if (question.selectedAnswers is List) {
          return question.selectedAnswers.map((a) {
            if (a is Map) return a['text'] ?? a['id'].toString();
            return a.toString();
          }).join(", ");
        }
      }

      if (question.type == "carte flash") {
        if (question.selectedAnswers == null ||
            question.selectedAnswers.isEmpty) {
          return "Non répondue";
        }

        // Flashcard answers should be a simple string
        if (question.selectedAnswers is String) {
          return question.selectedAnswers;
        }

        // If it's a map, get the first value
        if (question.selectedAnswers is Map) {
          return question.selectedAnswers.values.first?.toString() ?? "Non répondue";
        }

        // Default case
        return question.selectedAnswers.toString();
      }

      // 4. Cas général
      return _formatAnswer(question.selectedAnswers);
    }

    String _formatAnswer(dynamic answer) {
      if (answer == null) return "Non répondue";
      if (answer is Map) return answer.entries.map((e) => "${e.key} → ${e.value}").join(", ");
      if (answer is List) return answer.join(", ");
      return answer.toString();
    }
  }