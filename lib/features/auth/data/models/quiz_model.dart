import 'package:flutter/cupertino.dart';
import 'package:wizi_learn/features/auth/data/models/question_model.dart'; // Assurez-vous que c'est le bon chemin
import 'package:wizi_learn/features/auth/data/models/quiz_formation.dart';

class Quiz {
  final int id;
  final String titre;
  final String? description;
  final String? duree;
  final String niveau;
  final String status;
  final int nbPointsTotal;
  final QuizFormation formation;
  final List<Question> questions;

  Quiz({
    required this.id,
    required this.titre,
    this.description,
    this.duree,
    required this.niveau,
    this.status = 'inactif',
    required this.nbPointsTotal,
    required this.formation,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    // Mini formation intégrée
    final formationJson =
        json['formation'] is Map
            ? json['formation']
            : {
              'id': json['formation_id'] ?? 0,
              'titre': 'Formation inconnue',
              'description': '',
              'duree': '0',
              'categorie': 'Inconnue',
            };

    List<Question> questionsList = [];
    if (json['questions'] is List) {
      questionsList =
          (json['questions'] as List).map((q) {
            try {
              // Convertir les réponses si elles sont dans 'reponses' au lieu de 'answers'
              if (q is Map<String, dynamic>) {
                if (q['reponses'] != null && q['answers'] == null) {
                  q['answers'] = q['reponses'];
                }
                return Question.fromJson(q);
              }
              throw Exception('Question data is not a Map');
            } catch (e, stack) {
              debugPrint('Error parsing question: $e\n$stack');
              return Question(
                id: '0', // Utilisez une string comme dans le nouveau modèle
                text: q['text']?.toString() ?? 'Question non disponible',
                type: q['type']?.toString() ?? 'choix multiples',
                points: int.tryParse(q['points']?.toString() ?? '0') ?? 0,
                answers: [], // Utilisez 'answers' au lieu de 'reponses'
              );
            }
          }).toList();
    }

    return Quiz(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      titre: json['titre']?.toString() ?? 'Titre inconnu',
      description: json['description']?.toString(),
      duree: json['duree']?.toString(),
      status: json['status']?.toString() ?? 'inactif',
      niveau: json['niveau']?.toString() ?? 'débutant',
      nbPointsTotal:
          int.tryParse(json['nb_points_total']?.toString() ?? '0') ?? 0,
      formation: QuizFormation.fromJson(formationJson),
      questions: questionsList,
    );
  }
  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.writeln('Quiz {');
    buffer.writeln('  id: $id,');
    buffer.writeln('  titre: $titre,');
    buffer.writeln('  description: $description,');
    buffer.writeln('  duree: $duree,');
    buffer.writeln('  niveau: $niveau,');
    buffer.writeln('  status: $status,');
    buffer.writeln('  nbPointsTotal: $nbPointsTotal,');

    // Afficher la formation associée
    buffer.writeln(
      '  formation: ${formation.toString().replaceAll('\n', '\n  ')},',
    );

    // Afficher toutes les questions avec leurs réponses
    buffer.writeln('  questions: [');
    for (final question in questions) {
      buffer.writeln('    ${question.toString().replaceAll('\n', '\n    ')},');
    }
    buffer.writeln('  ]');

    buffer.writeln('}');
    return buffer.toString();
  }
}
