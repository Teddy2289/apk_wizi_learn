import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wizi_learn/core/services/quiz_persistence_service.dart';

void main() {
  late QuizPersistenceService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = QuizPersistenceService();
  });

  group('QuizPersistenceService', () {
    test('saveSession saves data correctly', () async {
      final sessionData = {
        'quizId': '1',
        'currentIndex': 5,
        'timeSpent': 100,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await service.saveSession('1', sessionData);

      final session = await service.getSession('1');
      expect(session, isNotNull);
      expect(session!['currentIndex'], 5);
      expect(session['timeSpent'], 100);
    });

    test('clearSession removes data', () async {
      final sessionData = {
        'quizId': '1',
        'currentIndex': 5,
      };

      await service.saveSession('1', sessionData);
      await service.clearSession('1');

      final session = await service.getSession('1');
      expect(session, isNull);
    });

    test('getLastUnfinishedQuiz returns the most recent session', () async {
      final now = DateTime.now();
      final olderDate = now.subtract(const Duration(hours: 1));
      final newerDate = now;

      final session1 = {
        'quizId': '1',
        'timestamp': olderDate.toIso8601String(),
      };
      final session2 = {
        'quizId': '2',
        'timestamp': newerDate.toIso8601String(),
      };

      await service.saveSession('1', session1);
      await service.saveSession('2', session2);

      final lastQuiz = await service.getLastUnfinishedQuiz();
      expect(lastQuiz, isNotNull);
      expect(lastQuiz!['quizId'], '2');
    });

    test('modal hidden state is persisted', () async {
      expect(await service.isModalHidden('1'), false);

      await service.setModalHidden('1', true);
      expect(await service.isModalHidden('1'), true);

      await service.clearModalHiddenState('1');
      expect(await service.isModalHidden('1'), false);
    });
  });
}
