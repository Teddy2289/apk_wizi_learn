/// Exemple d'utilisation du widget QuizResume
///
/// Ce fichier montre comment intégrer et utiliser le widget QuizResume
/// dans votre application Flutter
library;

import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/presentation/components/quiz_resume.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart';

/// Exemple 1: Utilisation simple avec données locales
class QuizResumeExample extends StatefulWidget {
  const QuizResumeExample({super.key});

  @override
  State<QuizResumeExample> createState() => _QuizResumeExampleState();
}

class _QuizResumeExampleState extends State<QuizResumeExample> {
  @override
  Widget build(BuildContext context) {
    // Données d'exemple
    final sampleQuestions = [
      Question(
        id: '1',
        text: 'Quelle est la capitale de la France ?',
        type: 'mcq',
        points: 2,
        answers: [],
        correctAnswers: 'Paris',
        isCorrect: true,
        selectedAnswers: 'Paris',
      ),
      Question(
        id: '2',
        text: 'Quel est le plus haut sommet du monde ?',
        type: 'mcq',
        points: 2,
        answers: [],
        correctAnswers: 'Everest',
        isCorrect: false,
        selectedAnswers: 'Kilimanjaro',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Résumé du Quiz')),
      body: QuizResume(
        questions: sampleQuestions,
        score: 50,
        correctAnswers: 1,
        totalQuestions: 2,
        timeSpent: 120,
        quizTitle: 'Géographie Niveau 1',
        completedAt: DateTime.now().toIso8601String(),
        onNewQuiz: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Nouveau quiz')));
        },
        onRestart: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Recommencer quiz')));
        },
        onNextQuiz: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Quiz suivant')));
        },
        showNextQuiz: true,
      ),
    );
  }
}

/// Exemple 2: Intégration avec QuizSummaryPage existant
///
/// À ajouter à quiz_summary_page.dart:
///
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(title: const Text('Résultats')),
///     body: QuizResume(
///       questions: widget.questions,
///       score: calculatedScore,
///       correctAnswers: calculatedCorrectAnswers,
///       totalQuestions: widget.totalQuestions,
///       timeSpent: widget.timeSpent,
///       quizTitle: widget.quizResult?['quizTitle'],
///       completedAt: widget.quizResult?['completedAt'],
///       onNewQuiz: () {
///         Navigator.pushReplacementNamed(context, '/quiz-page');
///       },
///       onRestart: () {
///         final quizId = widget.quizResult?['quizId'];
///         Navigator.pushReplacementNamed(
///           context,
///           '/quiz/$quizId/start',
///         );
///       },
///       onNextQuiz: _nextQuiz != null
///           ? () {
///               Navigator.pushNamed(
///                 context,
///                 '/quiz/${_nextQuiz!.id}/start',
///               );
///             }
///           : null,
///       showNextQuiz: _nextQuiz != null && !_showCountdown,
///     ),
///   );
/// }

/// Exemple 3: Avec formatage personnalisé des réponses
class AdvancedQuizResumeExample extends StatefulWidget {
  const AdvancedQuizResumeExample({super.key});

  @override
  State<AdvancedQuizResumeExample> createState() =>
      _AdvancedQuizResumeExampleState();
}

class _AdvancedQuizResumeExampleState extends State<AdvancedQuizResumeExample> {
  @override
  Widget build(BuildContext context) {
    // Questions avec différents types de réponses
    final complexQuestions = [
      // QCM simple
      Question(
        id: '1',
        text: 'Sélectionnez les capitales',
        type: 'mcq',
        points: 1,
        answers: [],
        correctAnswers: ['Paris', 'Londres'],
        isCorrect: true,
        selectedAnswers: ['Paris', 'Londres'],
      ),

      // Correspondance
      Question(
        id: '2',
        text: 'Associez les pays à leurs capitales',
        type: 'correspondance',
        points: 2,
        answers: [],
        correctAnswers: {'France': 'Paris', 'Allemagne': 'Berlin'},
        isCorrect: false,
        selectedAnswers: {
          'France': 'Paris',
          'Allemagne': 'Vienne', // Incorrecte
        },
      ),

      // Réarrangement
      Question(
        id: '3',
        text: 'Ordonnez les événements',
        type: 'rearrangement',
        points: 2,
        answers: [],
        correctAnswers: ['1789', '1815', '1870', '1945'],
        isCorrect: true,
        selectedAnswers: ['1789', '1815', '1870', '1945'],
      ),

      // Champ vide
      Question(
        id: '4',
        text: 'Complétez: La capitale de la France est ___',
        type: 'champ_vide',
        points: 1,
        answers: [],
        correctAnswers: 'Paris',
        isCorrect: false,
        selectedAnswers: 'Paris',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Avancé')),
      body: QuizResume(
        questions: complexQuestions,
        score: 120,
        correctAnswers: 3,
        totalQuestions: 4,
        timeSpent: 480, // 8 minutes
        quizTitle: 'Histoire et Géographie - Niveau Avancé',
        completedAt: DateTime.now().toIso8601String(),
        quizResult: {
          'quizId': '123',
          'newAchievements': [
            {'title': 'Historien', 'description': 'Score de 100% en histoire'},
          ],
        },
        onNewQuiz: () => Navigator.pop(context),
        onRestart:
            () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Réessai du quiz'))),
        onNextQuiz:
            () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Quiz suivant lancé'))),
        showNextQuiz: true,
      ),
    );
  }
}

/// Points clés d'implémentation:
///
/// 1. **Types de réponses supportés:**
///    - String simple: "Paris"
///    - List: ['A', 'B', 'C']
///    - Map: {'key1': 'value1', 'key2': 'value2'}
///    - null: Non répondue
///
/// 2. **Formatage automatique:**
///    - Les réponses sont formatées automatiquement
///    - Pas besoin de traitement préalable
///
/// 3. **Callbacks optionnels:**
///    - Tous les callbacks sont VoidCallback?
///    - Vérifier null avant utilisation
///
/// 4. **Responsive:**
///    - Adapté automatiquement à la taille de l'écran
///    - Fonctionne sur mobile, tablette, desktop
///
/// 5. **Accessibilité:**
///    - Contraste des couleurs respecté
///    - Icônes avec labels
///    - Tailles de texte lisibles

void main() {
  runApp(
    const MaterialApp(
      title: 'Quiz Resume Examples',
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: TabBar(tabs: [Tab(text: 'Simple'), Tab(text: 'Avancé')]),
          body: TabBarView(
            children: [QuizResumeExample(), AdvancedQuizResumeExample()],
          ),
        ),
      ),
    ),
  );
}
