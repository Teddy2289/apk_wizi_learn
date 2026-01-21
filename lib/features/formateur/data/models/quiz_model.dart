class Quiz {
  final int id;
  final String titre;
  final String? description;
  final int duree;
  final String niveau;
  final String status;
  final int nbQuestions;
  final List<Question> questions;

  Quiz({
    required this.id,
    required this.titre,
    this.description,
    required this.duree,
    required this.niveau,
    required this.status,
    required this.nbQuestions,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      titre: json['titre']?.toString() ?? '',
      description: json['description']?.toString(),
      duree: int.tryParse(json['duree']?.toString() ?? '30') ?? 30,
      niveau: json['niveau']?.toString() ?? 'debutant',
      status: json['status']?.toString() ?? 'brouillon',
      nbQuestions: int.tryParse(json['nb_questions']?.toString() ?? '0') ?? 0,
      questions: (json['questions'] as List?)
              ?.map((q) => Question.fromJson(q))
              .toList() ??
          [],
    );
  }
}

class Question {
  final int id;
  final String content;
  final String type; // qcm, vrai_faux
  final int points;
  final List<Reponse> reponses;

  Question({
    required this.id,
    required this.content,
    required this.type,
    required this.points,
    required this.reponses,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'qcm',
      points: int.tryParse(json['points']?.toString() ?? '1') ?? 1,
      reponses: (json['reponses'] as List?)
              ?.map((r) => Reponse.fromJson(r))
              .toList() ??
          [],
    );
  }
}

class Reponse {
  final int id;
  final String content;
  final bool isCorrect;

  Reponse({
    required this.id,
    required this.content,
    required this.isCorrect,
  });

  factory Reponse.fromJson(Map<String, dynamic> json) {
    return Reponse(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      content: json['content']?.toString() ?? '',
      isCorrect: json['is_correct'] == true || json['is_correct'] == 1 || json['is_correct'] == '1',
    );
  }
}
