import 'package:hive_flutter/hive_flutter.dart';

/// Service de cache simple utilisant Hive pour stocker des données hors ligne
/// Utilisé pour mettre en cache les données utilisateur, historiques, etc.
class CacheService {
  static const String _boxName = 'app_cache';
  Box? _box;

  /// Initialise le service de cache
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  /// Sauvegarde une valeur dans le cache avec une clé
  Future<void> put(String key, dynamic value) async {
    if (_box == null) throw Exception('Cache not initialized');
    await _box!.put(key, value);
    // Enregistrer le timestamp pour gérer l'expiration
    await _box!.put('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  /// Récupère une valeur du cache
  T? get<T>(String key) {
    if (_box == null) return null;
    return _box!.get(key) as T?;
  }

  /// Vérifie si une entrée du cache est encore valide
  bool isCacheValid(String key, Duration maxAge) {
    if (_box == null) return false;
    
    final timestamp = _box!.get('${key}_timestamp');
    if (timestamp == null) return false;
    
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    final age = DateTime.now().difference(cachedAt);
    
    return age < maxAge;
  }

  /// Supprime une entrée du cache
  Future<void> delete(String key) async {
    if (_box == null) return;
    await _box!.delete(key);
    await _box!.delete('${key}_timestamp');
  }

  /// Vide tout le cache
  Future<void> clear() async {
    if (_box == null) return;
    await _box!.clear();
  }

  /// Ferme le cache
  Future<void> close() async {
    await _box?.close();
  }
}
