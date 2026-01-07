class Question {
  final String id;
  final String text;
  final String type;
  final int? points;
  final String? astuce;
  final String? explication;
  final String? audioUrl;
  final String? mediaUrl;
  final List<Answer> answers;
  final List<Answer>? reponses;
  final List<Blank>? blanks;
  final List<MatchingItem>? matching;
  final FlashCard? flashcard;
  final List<WordBankItem>? wordbank;
  final List<String>? correctAnswers;
  final dynamic selectedAnswers;
  final bool? isCorrect;

  Question({
    required this.id,
    required this.text,
    required this.type,
    this.points,
    this.astuce,
    this.explication,
    this.audioUrl,
    this.mediaUrl,
    required this.answers,
    this.reponses,
    this.blanks,
    this.matching,
    this.flashcard,
    this.wordbank,
    this.correctAnswers,
    this.selectedAnswers,
    this.isCorrect,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'].toString(),
      text: json['text'],
      type: json['type'],
      points: json['points'],
      astuce: json['astuce'],
      explication: json['explication'],
      audioUrl: json['audioUrl'] ?? json['audio_url'],
      mediaUrl: json['mediaUrl'] ?? json['media_url'],
      answers: (json['answers'] as List<dynamic>?)
          ?.map((a) => Answer.fromJson(a))
          .toList() ?? [],
      reponses: (json['reponses'] as List<dynamic>?)
          ?.map((a) => Answer.fromJson(a))
          .toList(),
      blanks: (json['blanks'] as List<dynamic>?)
          ?.map((b) => Blank.fromJson(b))
          .toList(),
      matching: (json['matching'] as List<dynamic>?)
          ?.map((m) => MatchingItem.fromJson(m))
          .toList(),
      flashcard: json['flashcard'] != null
          ? FlashCard.fromJson(json['flashcard'])
          : null,
      wordbank: (json['wordbank'] as List<dynamic>?)
          ?.map((w) => WordBankItem.fromJson(w))
          .toList(),
      correctAnswers: (json['correctAnswers'] as List<dynamic>?)
          ?.map((c) => c.toString())
          .toList(),
      selectedAnswers: json['selectedAnswers'],
      isCorrect: json['isCorrect'],
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Question {');
    buffer.writeln('  id: $id,');
    buffer.writeln('  text: $text,');
    buffer.writeln('  type: $type,');
    buffer.writeln('  points: $points,');
    buffer.writeln('  astuce: $astuce,');
    buffer.writeln('  explication: $explication,');

    if (audioUrl != null) buffer.writeln('  audioUrl: $audioUrl,');
    if (mediaUrl != null) buffer.writeln('  mediaUrl: $mediaUrl,');

    // Answers
    if (answers.isNotEmpty) {
      buffer.writeln('  answers: [');
      for (final answer in answers) {
        buffer.writeln('    ${answer.toString().replaceAll('\n', '\n    ')},');
      }
      buffer.writeln('  ],');
    }

    // Other optional fields
    if (blanks != null && blanks!.isNotEmpty) {
      buffer.writeln('  blanks: $blanks,');
    }
    if (matching != null && matching!.isNotEmpty) {
      buffer.writeln('  matching: $matching,');
    }
    if (flashcard != null) {
      buffer.writeln('  flashcard: $flashcard,');
    }
    if (wordbank != null && wordbank!.isNotEmpty) {
      buffer.writeln('  wordbank: $wordbank,');
    }

    buffer.writeln('}');
    return buffer.toString();
  }
}

class Answer {
  final String id;
  final String text;
  final bool? isCorrect;
  final bool? is_correct;
  final String? flashcardBack;
  final bool? reponseCorrect;
  final int? position;
  final String? matchPair;
  final String? bankGroup;
  final String? questionId;
  final String? createdAt;
  final String? updatedAt;

  Answer({
    required this.id,
    required this.text,
    this.isCorrect,
    this.is_correct,
    this.flashcardBack,
    this.reponseCorrect,
    this.position,
    this.matchPair,
    this.bankGroup,
    this.questionId,
    this.createdAt,
    this.updatedAt,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'].toString(),
      text: json['text'],
      isCorrect: json['isCorrect'] ?? false,
      is_correct: json['is_correct'] == 1 || json['is_correct'] == true,
      flashcardBack: json['flashcard_back'] ?? json['flashcardBack'],
      reponseCorrect: json['reponse_correct'] ?? json['reponseCorrect'],
      position: json['position'],
      matchPair: json['match_pair'] ?? json['matchPair'],
      bankGroup: json['bank_group'] ?? json['bankGroup'],
      questionId: json['question_id']?.toString() ?? json['questionId']?.toString(),
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString(),
      updatedAt: json['updated_at']?.toString() ?? json['updatedAt']?.toString(),
    );
  }

  bool get correct => isCorrect ?? is_correct ?? false;

  @override
  String toString() {
    return 'Answer {'
        'id: $id, '
        'text: $text, '
        'isCorrect: $correct, '
        'flashcardBack: $flashcardBack, '
        'matchPair: $matchPair'
        '}';
  }
}

// ===== Modèles supplémentaires =====
class Blank {
  final String id;
  final String text;

  Blank({required this.id, required this.text});

  factory Blank.fromJson(Map<String, dynamic> json) {
    return Blank(
      id: json['id'].toString(),
      text: json['text'],
    );
  }

  @override
  String toString() => 'Blank {id: $id, text: $text}';
}

class MatchingItem {
  final String id;
  final String text;
  final String? matchPair;

  MatchingItem({required this.id, required this.text, this.matchPair});

  factory MatchingItem.fromJson(Map<String, dynamic> json) {
    return MatchingItem(
      id: json['id'].toString(),
      text: json['text'],
      matchPair: json['match_pair'] ?? json['matchPair'],
    );
  }

  @override
  String toString() => 'MatchingItem {id: $id, text: $text, matchPair: $matchPair}';
}

class FlashCard {
  final String front;
  final String back;

  FlashCard({required this.front, required this.back});

  factory FlashCard.fromJson(Map<String, dynamic> json) {
    return FlashCard(
      front: json['front'],
      back: json['back'] ?? json['flashcard_back'],
    );
  }

  @override
  String toString() => 'FlashCard {front: $front, back: $back}';
}

class WordBankItem {
  final String id;
  final String text;
  final String? bankGroup;

  WordBankItem({required this.id, required this.text, this.bankGroup});

  factory WordBankItem.fromJson(Map<String, dynamic> json) {
    return WordBankItem(
      id: json['id'].toString(),
      text: json['text'],
      bankGroup: json['bank_group'] ?? json['bankGroup'],
    );
  }

  @override
  String toString() => 'WordBankItem {id: $id, text: $text, bankGroup: $bankGroup}';
}
