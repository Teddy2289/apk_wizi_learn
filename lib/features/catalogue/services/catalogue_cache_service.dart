import 'package:wizi_learn/core/services/cache_service.dart';

/// Service pour gérer le cache du catalogue de formations
/// Permet l'accès hors ligne au catalogue complet et par catégorie
class CatalogueCacheService {
  final CacheService _cacheService;

  // Clés de cache
  static const String _allFormationsKey = 'cached_all_formations';
  static const String _categoriesKey = 'cached_categories';
  static const String _formationsByCategoryPrefix = 'cached_formations_category_';

  // Durée de validité du cache (2 jours)
  static const Duration _cacheDuration = Duration(days: 2);

  CatalogueCacheService(this._cacheService);

  /// Cache toutes les formations
  Future<void> cacheAllFormations(List<dynamic> formations) async {
    await _cacheService.put(_allFormationsKey, formations);
  }

  /// Récupère toutes les formations du cache
  List<dynamic>? getCachedAllFormations() {
    if (!_cacheService.isCacheValid(_allFormationsKey, _cacheDuration)) {
      return null;
    }
    
    return _cacheService.get<List>(_allFormationsKey);
  }

  /// Cache les catégories de formations
  Future<void> cacheCategories(List<dynamic> categories) async {
    await _cacheService.put(_categoriesKey, categories);
  }

  /// Récupère les catégories du cache
  List<dynamic>? getCachedCategories() {
    if (!_cacheService.isCacheValid(_categoriesKey, _cacheDuration)) {
      return null;
    }
    
    return _cacheService.get<List>(_categoriesKey);
  }

  /// Cache les formations d'une catégorie spécifique
  Future<void> cacheFormationsByCategory(
    String categoryId,
    List<dynamic> formations,
  ) async {
    final key = '$_formationsByCategoryPrefix$categoryId';
    await _cacheService.put(key, formations);
  }

  /// Récupère les formations d'une catégorie du cache
  List<dynamic>? getCachedFormationsByCategory(String categoryId) {
    final key = '$_formationsByCategoryPrefix$categoryId';
    
    if (!_cacheService.isCacheValid(key, _cacheDuration)) {
      return null;
    }
    
    return _cacheService.get<List>(key);
  }

  /// Vérifie si le catalogue est en cache
  bool hasCachedCatalogue() {
    return _cacheService.get(_allFormationsKey) != null;
  }

  /// Vide tout le cache du catalogue
  Future<void> clearCatalogueCache() async {
    await _cacheService.delete(_allFormationsKey);
    await _cacheService.delete(_categoriesKey);
    
    // Note: Les caches par catégorie restent pour ne pas tout supprimer
    // Ils seront automatiquement invalidés après 2 jours
  }

  /// Obtient la date de dernière mise en cache
  DateTime? getLastCacheDate() {
    final timestamp = _cacheService.get<int>('${_allFormationsKey}_timestamp');
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Force le rafraîchissement du cache (à appeler après mise à jour)
  Future<void> invalidateCache() async {
    await clearCatalogueCache();
  }
}
