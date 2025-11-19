import 'package:flutter/foundation.dart';
import 'package:wizi_learn/core/video/video_cache_manager.dart';

/// Extension pour VideoCacheManager avec diagnostics
extension VideoCacheManagerDiagnostics on VideoCacheManager {
  /// Affiche les stats du cache dans la console
  void printCacheStats() {
    final stats = getCacheStats();
    debugPrint('=== Video Cache Stats ===');
    debugPrint('Thumbnails cached: ${stats['thumbnails']}');
    debugPrint('Durations cached: ${stats['durations']}');
    debugPrint('Images cached: ${stats['images']}');
    debugPrint('========================');
  }

  /// Vide et réinitialise le cache avec statistiques
  void clearCacheWithLogging() {
    final stats = getCacheStats();
    debugPrint('Clearing cache with ${stats['thumbnails']} thumbnails, '
        '${stats['durations']} durations, ${stats['images']} images');
    clearCache();
    debugPrint('Cache cleared successfully');
  }
}
