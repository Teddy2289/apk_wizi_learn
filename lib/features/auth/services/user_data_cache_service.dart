import 'package:wizi_learn/core/services/cache_service.dart';
import 'package:wizi_learn/features/auth/data/models/user_model.dart';

/// Service pour gérer le cache des données utilisateur
/// Permet l'accès hors ligne aux informations du profil
class UserDataCacheService {
  final CacheService _cacheService;

  // Clés de cache
  static const String _userProfileKey = 'cached_user_profile';
  static const String _userStatsKey = 'cached_user_stats';
  static const String _userBadgesKey = 'cached_user_badges';
  static const String _quizHistoryKey = 'cached_quiz_history';

  // Durées de validité du cache
  static const Duration _profileCacheDuration = Duration(days: 7);
  static const Duration _statsCacheDuration = Duration(days: 1);
  static const Duration _badgesCacheDuration = Duration(days: 7);
  static const Duration _historyCacheDuration = Duration(days: 3);

  UserDataCacheService(this._cacheService);

  /// Cache le profil utilisateur
  Future<void> cacheUserProfile(User user) async {
    await _cacheService.put(_userProfileKey, user.toJson());
  }

  /// Récupère le profil utilisateur du cache
  User? getCachedUserProfile() {
    if (!_cacheService.isCacheValid(_userProfileKey, _profileCacheDuration)) {
      return null;
    }
    
    final json = _cacheService.get<Map<String, dynamic>>(_userProfileKey);
    return json != null ? User.fromJson(json) : null;
  }

  /// Cache les statistiques utilisateur
  Future<void> cacheUserStats(Map<String, dynamic> stats) async {
    await _cacheService.put(_userStatsKey, stats);
  }

  /// Récupère les statistiques du cache
  Map<String, dynamic>? getCachedUserStats() {
    if (!_cacheService.isCacheValid(_userStatsKey, _statsCacheDuration)) {
      return null;
    }
    
    return _cacheService.get<Map<String, dynamic>>(_userStatsKey);
  }

  /// Cache les badges utilisateur
  Future<void> cacheUserBadges(List<dynamic> badges) async {
    await _cacheService.put(_userBadgesKey, badges);
  }

  /// Récupère les badges du cache
  List<dynamic>? getCachedUserBadges() {
    if (!_cacheService.isCacheValid(_userBadgesKey, _badgesCacheDuration)) {
      return null;
    }
    
    return _cacheService.get<List>(_userBadgesKey);
  }

  /// Cache l'historique des quiz
  Future<void> cacheQuizHistory(List<dynamic> history) async {
    await _cacheService.put(_quizHistoryKey, history);
  }

  /// Récupère l'historique des quiz du cache
  List<dynamic>? getCachedQuizHistory() {
    if (!_cacheService.isCacheValid(_quizHistoryKey, _historyCacheDuration)) {
      return null;
    }
    
    return _cacheService.get<List>(_quizHistoryKey);
  }

  /// Vide tout le cache utilisateur
  Future<void> clearUserCache() async {
    await _cacheService.delete(_userProfileKey);
    await _cacheService.delete(_userStatsKey);
    await _cacheService.delete(_userBadgesKey);
    await _cacheService.delete(_quizHistoryKey);
  }

  /// Vérifie si des données utilisateur sont en cache
  bool hasAnyCachedData() {
    return _cacheService.get(_userProfileKey) != null ||
           _cacheService.get(_userStatsKey) != null ||
           _cacheService.get(_userBadgesKey) != null ||
           _cacheService.get(_quizHistoryKey) != null;
  }
}
