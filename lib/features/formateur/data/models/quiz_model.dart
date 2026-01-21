class Quiz {
  final int id;
  final String titre;
  final String? description;
  final int duree;
  final String niveau;
  final String status;
  final int nbQuestions;
  final int? formationId;
  final List<Question> questions;

  Quiz({
    required this.id,
    required this.titre,
    this.description,
    required this.duree,
    required this.niveau,
    required this.status,
    required this.nbQuestions,
    this.formationId,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v, {int fallback = 0}) =>
        int.tryParse(v?.toString() ?? '') ?? fallback;

    final parsedQuestions = (json['questions'] as List?)
            ?.map((q) => Question.fromJson(q as Map<String, dynamic>))
            .toList() ??
        [];

    return Quiz(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      titre: json['titre']?.toString() ?? '',
      description: json['description']?.toString(),
      duree: parseInt(json['duree'], fallback: 30),
      niveau: json['niveau']?.toString() ?? 'débutant',
      status: json['status']?.toString() ?? 'brouillon',
      nbQuestions: parseInt(json['nb_questions'], fallback: parsedQuestions.length),
      formationId: json['formation_id'] != null 
          ? int.tryParse(json['formation_id'].toString()) 
          : null,
      questions: parsedQuestions,
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
    // Support Laravel payload:
    // { question: "...", type: "...", reponses: [{ reponse: "...", correct: true }] }
    // and legacy payload:
    // { content: "...", points: 1, reponses: [{ content: "...", is_correct: 1 }] }
    int parseInt(dynamic v, {int fallback = 0}) =>
        int.tryParse(v?.toString() ?? '') ?? fallback;

    return Question(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      content: (json['content'] ?? json['question'] ?? '').toString(),
      type: (json['type'] ?? 'qcm').toString(),
      // Laravel payload doesn't include points; default to 1
      points: parseInt(json['points'], fallback: 1),
      reponses: (json['reponses'] as List?)
              ?.map((r) => Reponse.fromJson(r as Map<String, dynamic>))
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
    final rawCorrect = json['is_correct'] ?? json['correct'];
    return Reponse(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      content: (json['content'] ?? json['reponse'] ?? '').toString(),
      isCorrect: rawCorrect == true ||
          rawCorrect == 1 ||
          rawCorrect == '1',
    );
  }
}
