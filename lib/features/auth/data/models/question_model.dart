
class Question {
  final String id;
  final int? quizId;
  final String text;
  final String type;
  final String? explication;
  final int points;
  final String? astuce;
  final String? mediaUrl;
  final String? audioUrl;
  final List<Answer> answers;
  final dynamic correctAnswers;
  final QuestionMeta? meta;
  final List<Blank>? blanks;
  final List<MatchingItem>? matching;
  final FlashCard? flashcard;
  final List<WordBankItem>? wordbank;
  bool? isCorrect;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  dynamic selectedAnswers;

  Question({
    required this.id,
    this.quizId,
    required this.text,
    required this.type,
    this.explication,
    this.points = 1,
    this.astuce,
    this.mediaUrl,
    this.audioUrl,
    required this.answers,
    this.correctAnswers,
    this.meta,
    this.blanks,
    this.matching,
    this.flashcard,
    this.wordbank,
    this.isCorrect,
    this.selectedAnswers,
    this.createdAt,
    this.updatedAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final type = _validateQuestionType(json['type']);
    final answers = <Answer>[];

    if (json['answers'] is List || json['reponses'] is List) {
      final rawAnswers = (json['answers'] ?? json['reponses']) as List;
      answers.addAll(rawAnswers.map((a) => Answer.fromJson(a)));
    }

    // Handle correct answers - support both Map and List formats
    dynamic correctAnswers;
    if (json['correctAnswers'] != null || json['correct_answers'] != null) {
      final rawCorrectAnswers =
          json['correctAnswers'] ?? json['correct_answers'];
      if (rawCorrectAnswers is Map) {
        correctAnswers = Map<String, String>.from(rawCorrectAnswers);
      } else if (rawCorrectAnswers is List) {
        correctAnswers = List<dynamic>.from(rawCorrectAnswers);
      }
    }

    // Handle selected answers - support both Map and List formats
    dynamic selectedAnswers;
    if (json['selectedAnswers'] != null || json['selected_answers'] != null) {
      final rawSelectedAnswers = json['selectedAnswers'] ?? json['selected_answers'];

      if (rawSelectedAnswers is Map) {
        selectedAnswers = Map<String, String>.from(rawSelectedAnswers);
      }
      else if (rawSelectedAnswers is List) {
        // Cas spécial pour les questions audio
        if (json['type'] == 'question audio' && rawSelectedAnswers.isNotEmpty) {
          final firstAnswer = rawSelectedAnswers.first;
          if (firstAnswer is Map) {
            selectedAnswers = firstAnswer;
          } else {
            selectedAnswers = {'text': firstAnswer.toString()};
          }
        } else {
          selectedAnswers = List<dynamic>.from(rawSelectedAnswers);
        }
      }
      else if (rawSelectedAnswers is String) {
        // Pour les questions audio avec réponse directe en String
        if (json['type'] == 'question audio') {
          selectedAnswers = {'text': rawSelectedAnswers};
        } else {
          selectedAnswers = rawSelectedAnswers;
        }
      }
    }

    QuestionMeta? meta;
    if (json['meta'] != null) {
      if (json['meta'] is QuestionMeta) {
        meta = json['meta'] as QuestionMeta;
      } else if (json['meta'] is Map) {
        meta = QuestionMeta.fromJson(json['meta']);
      }
    }

    return Question(
      id: json['id']?.toString() ?? '0',
      quizId: json['quiz_id'] as int?,
      text: json['text'] as String? ?? '',
      type: type,
      explication: json['explication'] as String?,
      points: _parseInt(json['points']),
      astuce: json['astuce'] as String?,
      mediaUrl: json['media_url'] ?? json['mediaUrl'],
      audioUrl: json['audio_url'] ?? json['audioUrl'],
      answers: answers,
      isCorrect: json['is_correct'] ?? json['isCorrect'] ?? false,
      meta: meta,
      blanks:
          json['blanks'] is List
              ? (json['blanks'] as List).map((b) => Blank.fromJson(b)).toList()
              : null,
      matching:
          json['matching'] is List
              ? (json['matching'] as List)
                  .map((m) => MatchingItem.fromJson(m))
                  .toList()
              : null,
      flashcard:
          json['flashcard'] is Map
              ? FlashCard.fromJson(json['flashcard'])
              : null,
      wordbank:
          json['wordbank'] is List
              ? (json['wordbank'] as List)
                  .map((w) => WordBankItem.fromJson(w))
                  .toList()
              : null,
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
      correctAnswers: correctAnswers,
      selectedAnswers: selectedAnswers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'text': text,
      'type': type,
      'explication': explication,
      'points': points,
      'astuce': astuce,
      'media_url': mediaUrl,
      'audio_url': audioUrl,
      'answers': answers.map((a) => a.toJson()).toList(),
      'meta': meta?.toJson(),
      'blanks': blanks?.map((b) => b.toJson()).toList(),
      'matching': matching?.map((m) => m.toJson()).toList(),
      'flashcard': flashcard?.toJson(),
      'wordbank': wordbank?.map((w) => w.toJson()).toList(),
      'is_correct': isCorrect,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'correct_answers': correctAnswers,
      'selected_answers': selectedAnswers,
    };
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date);
    return null;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 1;
    return 1;
  }

  static String _validateQuestionType(String? type) {
    const validTypes = {
      'question audio',
      'remplir le champ vide',
      'carte flash',
      'correspondance',
      'choix multiples',
      'rearrangement',
      'vrai/faux',
      'banque de mots',
    };
    return type != null && validTypes.contains(type) ? type : 'choix multiples';
  }

  bool get isValid => text.isNotEmpty && answers.isNotEmpty;

  List<Answer> get correctAnswersList =>
      answers.where((a) => a.correct).toList();

  Map<String, String> extractCorrectPairs() {
    final pairs = <String, String>{};
    if (type != 'correspondance') return pairs;

    final leftItems = answers.where((a) => a.matchPair == 'left');
    final rightItems = answers.where((a) => a.matchPair == 'right');

    for (final left in leftItems) {
      final right = rightItems.firstWhere(
        (r) => r.bankGroup == left.bankGroup,
        orElse:
            () =>
                null
                    as Answer, // This line will still cause a warning, so let's fix it properly below
      );
      if (right != null) {
        pairs[left.text] = right.text;
      }
    }
    return pairs;
  }

  @override
  String toString() {
    return 'Question('
        'id: $id, '
        'text: $text, '
        'type: $type, '
        'isCorrect: $isCorrect, '
        'selectedAnswers: $selectedAnswers, '
        'correctAnswers: $correctAnswers, '
        'meta: ${meta?.toString()}'
        ')';
  }

  Question copyWith({
    String? id,
    int? quizId,
    String? text,
    String? type,
    String? explication,
    int? points,
    String? astuce,
    String? mediaUrl,
    String? audioUrl,
    List<Answer>? answers,
    dynamic correctAnswers,
    QuestionMeta? meta,
    List<Blank>? blanks,
    List<MatchingItem>? matching,
    FlashCard? flashcard,
    List<WordBankItem>? wordbank,
    bool? isCorrect,
    DateTime? createdAt,
    DateTime? updatedAt,
    dynamic selectedAnswers,
  }) {
    return Question(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      text: text ?? this.text,
      type: type ?? this.type,
      explication: explication ?? this.explication,
      points: points ?? this.points,
      astuce: astuce ?? this.astuce,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      answers: answers ?? this.answers,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      meta: meta ?? this.meta,
      blanks: blanks ?? this.blanks,
      matching: matching ?? this.matching,
      flashcard: flashcard ?? this.flashcard,
      wordbank: wordbank ?? this.wordbank,
      isCorrect: isCorrect ?? this.isCorrect,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
    );
  }
}

class Answer {
  final String id;
  final String text;
  final bool correct;
  final String? flashcardBack;
  final int? position;
  final String? matchPair;
  final String? bankGroup;
  final String? questionId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Answer({
    required this.id,
    required this.text,
    required this.correct,
    this.flashcardBack,
    this.position,
    this.matchPair,
    this.bankGroup,
    this.questionId,
    this.createdAt,
    this.updatedAt,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id']?.toString() ?? '0',
      text: json['text'] as String? ?? '',
      correct:
          (json['is_correct'] ?? json['isCorrect']) == true ||
          (json['is_correct'] ?? json['isCorrect']) == 1,
      flashcardBack: json['flashcard_back'] ?? json['flashcardBack'],
      position:
          json['position'] != null
              ? int.tryParse(json['position'].toString())
              : null,
      matchPair: json['match_pair'] ?? json['matchPair'],
      bankGroup:
          json['bank_group']?.toString().toLowerCase() ??
          json['bankGroup']?.toString().toLowerCase(),
      questionId:
          json['question_id']?.toString() ?? json['questionId']?.toString(),
      createdAt:
          json['created_at'] is String
              ? DateTime.tryParse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] is String
              ? DateTime.tryParse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'is_correct': correct,
      'flashcard_back': flashcardBack,
      'position': position,
      'match_pair': matchPair,
      'bank_group': bankGroup,
      'question_id': questionId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Answer copyWith({
    String? id,
    String? text,
    bool? correct,
    String? flashcardBack,
    int? position,
    String? matchPair,
    String? bankGroup,
    String? questionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Answer(
      id: id ?? this.id,
      text: text ?? this.text,
      correct: correct ?? this.correct,
      flashcardBack: flashcardBack ?? this.flashcardBack,
      position: position ?? this.position,
      matchPair: matchPair ?? this.matchPair,
      bankGroup: bankGroup ?? this.bankGroup,
      questionId: questionId ?? this.questionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Blank {
  final String id;
  final String text;

  Blank({required this.id, required this.text});

  factory Blank.fromJson(Map<String, dynamic> json) {
    return Blank(
      id: json['id']?.toString() ?? '0',
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text};
  }
}

class MatchingItem {
  final String id;
  final String text;
  final String? matchPair;

  MatchingItem({required this.id, required this.text, this.matchPair});

  factory MatchingItem.fromJson(Map<String, dynamic> json) {
    return MatchingItem(
      id: json['id']?.toString() ?? '0',
      text: json['text'] as String? ?? '',
      matchPair: json['match_pair'] ?? json['matchPair'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'match_pair': matchPair};
  }
}

class FlashCard {
  final String front;
  final String back;

  FlashCard({required this.front, required this.back});

  factory FlashCard.fromJson(Map<String, dynamic> json) {
    return FlashCard(
      front: json['front'] as String? ?? '',
      back: json['back'] ?? json['flashcard_back'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'front': front, 'back': back};
  }
}

class WordBankItem {
  final String id;
  final String text;
  final String? bankGroup;

  WordBankItem({required this.id, required this.text, this.bankGroup});

  factory WordBankItem.fromJson(Map<String, dynamic> json) {
    return WordBankItem(
      id: json['id']?.toString() ?? '0',
      text: json['text'] as String? ?? '',
      bankGroup: json['bank_group'] ?? json['bankGroup'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'bank_group': bankGroup};
  }
}

class QuestionMeta {
  final int? timeLimit;
  final bool? hasHint;
  final bool? showSolution;
  final int? attemptsAllowed;
  final dynamic correctAnswers;
  final dynamic selectedAnswers;
  // champs isCorrect
  final bool? isCorrect;

  QuestionMeta({
    this.timeLimit,
    this.hasHint,
    this.showSolution,
    this.attemptsAllowed,
    this.correctAnswers,
    this.selectedAnswers,
    this.isCorrect,
  });

  factory QuestionMeta.fromJson(Map<String, dynamic> json) {
    return QuestionMeta(
      timeLimit: json['time_limit'] as int?,
      hasHint: json['has_hint'] as bool?,
      showSolution: json['show_solution'] as bool?,
      attemptsAllowed: json['attempts_allowed'] as int?,
      correctAnswers: json['correct_answers'],
      selectedAnswers: json['selected_answers'],
      isCorrect: json['is_correct'] ?? json['isCorrect'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time_limit': timeLimit,
      'has_hint': hasHint,
      'show_solution': showSolution,
      'attempts_allowed': attemptsAllowed,
      'correct_answers': correctAnswers,
      'selected_answers': selectedAnswers,
      'is_correct': isCorrect,
    };
  }
}

class QuizSubmissionResponse {
  final int id;
  final int quizId;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final int timeSpent;
  final List<Question> questions;

  QuizSubmissionResponse({
    required this.id,
    required this.quizId,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.timeSpent,
    required this.questions,
  });

  factory QuizSubmissionResponse.fromJson(Map<String, dynamic> json) {
    List<Question> parsedQuestions = [];

    if (json['questions'] is List) {
      parsedQuestions =
          (json['questions'] as List).map((q) {
            try {
              return Question.fromJson(q);
            } catch (e) {
              // debugPrint('Error parsing question: $e');
              return Question(
                id: q['id']?.toString() ?? '0',
                text: q['text'] ?? '',
                type: q['type'] ?? 'choix multiples',
                answers: [],
                isCorrect: q['isCorrect'] ?? false,
                selectedAnswers: q['selectedAnswers'],
              );
            }
          }).toList();
    }

    return QuizSubmissionResponse(
      id: json['id'] as int? ?? 0,
      quizId: json['quizId'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? parsedQuestions.length,
      timeSpent: json['timeSpent'] as int? ?? 0,
      questions: parsedQuestions,
    );
  }
}
