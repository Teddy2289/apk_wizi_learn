import 'package:collection/collection.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';

class QuizUtils {
  static String normalizeString(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String formatCorrectAnswer(Question question) {
    switch (question.type) {
      case "remplir le champ vide":
        final blanks = <String, String>{};
        for (var a in question.answers) {
          if (a.bankGroup != null && a.correct) {
            blanks[a.bankGroup!] = a.text;
          }
        }
        if (blanks.isNotEmpty) return blanks.values.join(", ");
        return question.answers
            .where((a) => a.correct)
            .map((a) => a.text)
            .join(", ");
      case "correspondance":
        if (question.correctAnswers is Map) {
          final pairs = (question.correctAnswers as Map).map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          );
          return pairs.entries.map((e) => "${e.key} → ${e.value}").join(", ");
        }
        return "Aucune réponse correcte définie";

      case "carte flash":
        final correct = question.answers.firstWhere(
          (a) => a.correct,
          orElse:
              () => Answer(id: "-1", text: "Aucune réponse", correct: false),
        );
        return correct.text;

      case "rearrangement":
        final ordered =
            question.answers.where((a) => a.correct).toList()
              ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
        return ordered.map((a) => a.text).join(" → ");

      case "banque de mots":
        return question.answers
            .where((a) => a.correct)
            .map((a) => a.text)
            .join(", ");

      default:
        return question.answers
            .where((a) => a.correct)
            .map((a) => a.text)
            .join(", ");
    }
  }

  static bool isAnswerCorrect(Question question, dynamic userAnswer) {
    if (userAnswer == null) return false;

    switch (question.type) {
      case "remplir le champ vide":
        final correctBlanks = <String, String>{};
        for (var a in question.answers) {
          if (a.bankGroup != null && a.correct) {
            correctBlanks[a.bankGroup!] = a.text;
          }
        }
        if (correctBlanks.isNotEmpty && userAnswer is Map) {
          return correctBlanks.entries.every((entry) {
            final userVal = userAnswer[entry.key]?.toString();
            return userVal != null &&
                normalizeString(userVal) == normalizeString(entry.value);
          });
        }
        return false;
      case "correspondance":
        // Vérifier d'abord meta.isCorrect
        if (question.meta?.isCorrect != null) {
          return question.meta!.isCorrect!;
        }

        // Convert user answer to text-based format if it's ID-based
        final Map<String, String> userAnswerMap = {};
        if (userAnswer is Map) {
          for (var entry in userAnswer.entries) {
            final answerId = entry.key.toString();
            final answerText = entry.value.toString();

            // Find the corresponding answer text for the ID
            final answer = question.answers.firstWhere(
              (a) => a.id.toString() == answerId,
              orElse: () => Answer(id: '-1', text: '', correct: false),
            );

            if (answer.id != '-1') {
              userAnswerMap[answer.text] = answerText;
            }
          }
        }

        bool mapsEqual(Map<String, String> a, Map<String, String> b) {
          if (a.length != b.length) return false;
          for (var key in a.keys) {
            if (a[key] != b[key]) return false;
          }
          return true;
        }
        // Compare with correct answers
        if (question.correctAnswers is Map) {
          final correctAnswers = Map<String, String>.from(
            question.correctAnswers as Map,
          );
          return mapsEqual(userAnswerMap, correctAnswers);
        }

        return false;

      case "rearrangement":
        if (userAnswer is! List) return false;
        final correctOrder =
            question.answers
                .where((a) => a.correct)
                .map((a) => a.id.toString())
                .toList();
        return const ListEquality().equals(
          userAnswer.map((e) => e.toString()).toList(),
          correctOrder,
        );

      case "carte flash":
        final correct = question.answers.firstWhere(
          (a) => a.correct,
          orElse: () => Answer(id: "-1", text: "", correct: false),
        );
        return correct.id != "-1" &&
            normalizeString(correct.text) ==
                normalizeString(userAnswer.toString());

      case "banque de mots":
        if (userAnswer is! List) return false;
        final correctSet =
            question.answers
                .where((a) => a.correct)
                .map((a) => normalizeString(a.text))
                .toSet();
        final userSet =
            userAnswer.map((e) => normalizeString(e.toString())).toSet();
        return correctSet.length == userSet.length &&
            correctSet.containsAll(userSet);

      default:
        if (userAnswer is List) {
          final correctSet =
              question.answers
                  .where((a) => a.correct)
                  .map((a) => a.id.toString())
                  .toSet();
          final userSet = userAnswer.map((e) => e.toString()).toSet();
          return correctSet.length == userSet.length &&
              correctSet.containsAll(userSet);
        }
        return question.answers.any(
          (a) => a.correct && a.id.toString() == userAnswer.toString(),
        );
    }
  }

  static String cleanString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final s = value.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  static double cleanDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    return double.tryParse(value.toString()) ?? fallback;
  }

  static int cleanInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    return int.tryParse(value.toString()) ?? fallback;
  }
}
