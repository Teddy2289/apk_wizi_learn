import 'package:flutter/foundation.dart';
import 'package:wizi_learn/core/services/quiz_persistence_service.dart';

/// Provider that manages resume quiz functionality
/// Similar to React's useResumeQuiz hook
class ResumeQuizProvider with ChangeNotifier {
  final QuizPersistenceService _persistenceService;

  Map<String, dynamic>? _unfinishedQuiz;
  bool _isModalHidden = false;
  bool _isLoading = false;

  ResumeQuizProvider(this._persistenceService);

  // Getters (equivalent to React hook return values)
  Map<String, dynamic>? get unfinishedQuiz => _unfinishedQuiz;
  bool get isModalHidden => _isModalHidden;
  bool get isLoading => _isLoading;
  
  /// Whether the modal should be shown
  /// Modal is shown when there's an unfinished quiz and it's not hidden
  bool get shouldShowModal => _unfinishedQuiz != null && !_isModalHidden;
  
  /// Whether the floating button should be shown
  /// Button is shown when there's an unfinished quiz and modal is hidden
  bool get shouldShowButton => _unfinishedQuiz != null && _isModalHidden;

  /// Check for unfinished quiz sessions
  /// Should be called when the app starts or when navigating to quiz pages
  Future<void> checkForUnfinishedQuiz() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final session = await _persistenceService.getLastUnfinishedQuiz();
      
      if (session != null) {
        final quizId = session['quizId'] as String;
        final isHidden = await _persistenceService.isModalHidden(quizId);
        
        _unfinishedQuiz = session;
        _isModalHidden = isHidden;
      } else {
        _unfinishedQuiz = null;
        _isModalHidden = false;
      }
    } catch (e) {
      debugPrint('Error checking for unfinished quiz: $e');
      _unfinishedQuiz = null;
      _isModalHidden = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Hide the modal temporarily (show floating button instead)
  /// Equivalent to React's hideModal()
  Future<void> hideModal() async {
    if (_unfinishedQuiz == null) return;
    
    final quizId = _unfinishedQuiz!['quizId'] as String;
    await _persistenceService.setModalHidden(quizId, true);
    
    _isModalHidden = true;
    notifyListeners();
  }

  /// Permanently dismiss the quiz (delete the session)
  /// Equivalent to React's dismissQuiz()
  Future<void> dismissQuiz(String quizId) async {
    await _persistenceService.clearSession(quizId);
    await _persistenceService.clearModalHiddenState(quizId);
    
    _unfinishedQuiz = null;
    _isModalHidden = false;
    notifyListeners();
  }

  /// Reset the provider state
  /// Useful when navigating away or after quiz completion
  void reset() {
    _unfinishedQuiz = null;
    _isModalHidden = false;
    _isLoading = false;
    notifyListeners();
  }

  /// Refresh the unfinished quiz data
  /// Call this after returning from a quiz session
  Future<void> refresh() async {
    await checkForUnfinishedQuiz();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
