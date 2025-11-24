import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:wizi_learn/core/services/quiz_persistence_service.dart';
import 'package:wizi_learn/features/auth/data/repositories/quiz_session_repository.dart';

/// Service hybride pour la gestion des sessions de quiz
/// Utilise l'API quand connecté, sinon fallback sur le stockage local
class QuizSessionService {
  final QuizSessionRepository sessionRepository;
  final QuizPersistenceService persistenceService;

  QuizSessionService({
    required this.sessionRepository,
    required this.persistenceService,
  });

  /// Vérifie la connectivité réseau
  Future<bool> _isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  /// Vérifie s'il existe une session de quiz non terminée
  Future<Map<String, dynamic>?> checkUnfinishedQuiz(int quizId) async {
    final isOnline = await _isOnline();

    if (isOnline) {
      try {
        // Essayer de récupérer depuis le serveur
        final serverSession = await sessionRepository.checkUnfinishedSession(quizId);
        
        if (serverSession != null) {
          debugPrint('✅ Session trouvée sur le serveur');
          return {
            ...serverSession,
            'source': 'server',
          };
        }
      } catch (e) {
        debugPrint('❌ Erreur serveur, fallback vers local: $e');
      }
    }

    // Fallback vers le stockage local
    final localSession = await persistenceService.getSession(quizId.toString());
    if (localSession != null) {
      debugPrint('✅ Session locale trouvée');
      return {
        ...localSession,
        'source': 'local',
      };
    }

    return null;
  }

  /// Démarre une nouvelle session de quiz
  Future<int?> startQuizSession(int quizId, List<int> questionIds) async {
    final isOnline = await _isOnline();

    if (isOnline) {
      try {
        final participationId = await sessionRepository.startSession(
          quizId,
          questionIds,
        );
        
        if (participationId != null) {
          debugPrint('✅ Session démarrée sur le serveur: $participationId');
          
          // Sauvegarder aussi localement pour backup
          await persistenceService.saveSession(
            quizId.toString(),
            {
              'participationId': participationId,
              'quizId': quizId,
              'currentIndex': 0,
              'questionIds': questionIds,
              'answers': {},
              'timeSpent': 0,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
          
          return participationId;
        }
      } catch (e) {
        debugPrint('❌ Erreur démarrage session serveur: $e');
      }
    }

    // Mode offline : pas de participationId, juste stockage local
    debugPrint('📴 Mode offline: stockage local uniquement');
    await persistenceService.saveSession(
      quizId.toString(),
      {
        'quizId': quizId,
        'currentIndex': 0,
        'questionIds': questionIds,
        'answers': {},
        'timeSpent': 0,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    return null; // Pas de participationId en mode offline
  }

  /// Sauvegarde la progression de la session
  Future<void> saveProgress({
    int? participationId,
    required String quizId,
    required int currentQuestionIndex,
    required Map<String, dynamic> answers,
    required int timeSpent,
    int? currentQuestionId,
  }) async {
    // Toujours sauvegarder localement d'abord (backup)
    await persistenceService.saveSession(
      quizId,
      {
        'participationId': participationId,
        'quizId': quizId,
        'currentIndex': currentQuestionIndex,
        'currentQuestionId': currentQuestionId,
        'answers': answers,
        'timeSpent': timeSpent,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Si en ligne et on a un participationId, sauvegarder sur le serveur
    final isOnline = await _isOnline();
    if (isOnline && participationId != null) {
      try {
        final success = await sessionRepository.saveSessionProgress(
          quizId: int.parse(quizId),
          participationId: participationId,
          currentQuestionId: currentQuestionId,
          answers: answers,
          timeSpent: timeSpent,
        );

        if (success) {
          debugPrint('✅ Progression sauvegardée sur le serveur');
        } else {
          debugPrint('⚠️ Échec sauvegarde serveur, conservé localement');
        }
      } catch (e) {
        debugPrint('❌ Erreur sauvegarde serveur: $e');
      }
    } else {
      debugPrint('📴 Progression sauvegardée localement uniquement');
    }
  }

  /// Termine une session de quiz
  Future<Map<String, dynamic>?> completeSession({
    int? participationId,
    required String quizId,
    required Map<String, dynamic> answers,
    required int timeSpent,
  }) async {
    final isOnline = await _isOnline();

    if (isOnline && participationId != null) {
      try {
        final result = await sessionRepository.completeSession(
          participationId: participationId,
          answers: answers,
          timeSpent: timeSpent,
        );

        if (result != null) {
          // Nettoyer le stockage local après succès
          await persistenceService.clearSession(quizId);
          debugPrint('✅ Quiz terminé sur le serveur');
          return result;
        }
      } catch (e) {
        debugPrint('❌ Erreur finalisation serveur: $e');
        // On va continuer avec le fallback local
      }
    }

    // Fallback: nettoyer localement et retourner null
    // (le quiz sera soumis via l'ancien système)
    await persistenceService.clearSession(quizId);
    debugPrint('📴 Quiz terminé en mode offline');
    return null;
  }

  /// Abandonne une session de quiz
  Future<void> abandonSession({
    int? participationId,
    required String quizId,
  }) async {
    // Toujours nettoyer localement
    await persistenceService.clearSession(quizId);

    // Si on a un participationId et qu'on est en ligne, supprimer sur le serveur
    final isOnline = await _isOnline();
    if (isOnline && participationId != null) {
      try {
        await sessionRepository.abandonSession(participationId);
        debugPrint('✅ Session abandonnée sur le serveur');
      } catch (e) {
        debugPrint('❌ Erreur abandon session serveur: $e');
      }
    } else {
      debugPrint('📴 Session abandonnée localement');
    }
  }

  /// Synchronise les sessions locales avec le serveur (après reconnexion)
  Future<void> syncLocalSessions() async {
    final isOnline = await _isOnline();
    if (!isOnline) {
      debugPrint('📴 Pas de connexion, synchronisation impossible');
      return;
    }

    debugPrint('🔄 Synchronisation des sessions locales...');
    
    // Cette méthode pourrait être améliorée pour récupérer toutes les sessions locales
    // et les envoyer au serveur, mais pour l'instant on laisse la gestion manuelle
  }
}
