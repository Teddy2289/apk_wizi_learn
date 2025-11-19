import 'package:flutter/material.dart';

/// Gestionnaire de cache pour optimiser le chargement des vidéos et thumbnails
class VideoCacheManager {
  static final VideoCacheManager _instance = VideoCacheManager._internal();

  factory VideoCacheManager() {
    return _instance;
  }

  VideoCacheManager._internal();

  // Cache pour les thumbnails URL
  final Map<String, String> _thumbnailCache = {};

  // Cache pour les durées de vidéo
  final Map<int, Duration> _durationCache = {};

  // Cache pour les images précachées
  final Map<String, ImageProvider> _imageCache = {};

  // Limite de taille du cache
  static const int _maxCacheSize = 100;

  /// Récupère un thumbnail URL du cache ou le calcule
  String getThumbnailUrl(String videoUrl, String Function() urlGenerator) {
    if (_thumbnailCache.containsKey(videoUrl)) {
      return _thumbnailCache[videoUrl]!;
    }

    final url = urlGenerator();
    _addToCache(_thumbnailCache, videoUrl, url);
    return url;
  }

  /// Récupère une durée du cache
  Duration? getCachedDuration(int mediaId) {
    return _durationCache[mediaId];
  }

  /// Ajoute une durée au cache
  void cacheDuration(int mediaId, Duration duration) {
    _durationCache[mediaId] = duration;
    _manageCacheSize(_durationCache);
  }

  /// Récupère une image précachée
  ImageProvider? getCachedImage(String url) {
    return _imageCache[url];
  }

  /// Ajoute une image au cache
  void cacheImage(String url, ImageProvider image) {
    _imageCache[url] = image;
    _manageCacheSize(_imageCache);
  }

  /// Ajoute un élément au cache avec limite de taille
  void _addToCache<K, V>(Map<K, V> cache, K key, V value) {
    cache[key] = value;
    _manageCacheSize(cache);
  }

  /// Gère la taille du cache (FIFO si dépassement)
  void _manageCacheSize<K, V>(Map<K, V> cache) {
    if (cache.length > _maxCacheSize) {
      final keysToRemove =
          cache.keys.take(cache.length - _maxCacheSize).toList();
      for (final key in keysToRemove) {
        cache.remove(key);
      }
    }
  }

  /// Vide le cache
  void clearCache() {
    _thumbnailCache.clear();
    _durationCache.clear();
    _imageCache.clear();
  }

  /// Obtient les statistiques du cache
  Map<String, int> getCacheStats() {
    return {
      'thumbnails': _thumbnailCache.length,
      'durations': _durationCache.length,
      'images': _imageCache.length,
    };
  }
}
