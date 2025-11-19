/// Exemple d'utilisation avancée du système de cache vidéo
/// Ce fichier montre des cas d'usage pratiques

import 'package:flutter/material.dart';
import 'package:wizi_learn/core/video/video_cache_manager.dart';
import 'package:wizi_learn/core/video/video_cache_extensions.dart';

// ============================================================================
// EXEMPLE 1: Utilisation Basique du Cache
// ============================================================================

void exempleBasique() {
  final cacheManager = VideoCacheManager();

  // Obtenir un thumbnail URL avec cache automatique
  String getThumbnailWithCache(String videoUrl) {
    return cacheManager.getThumbnailUrl(
      videoUrl,
      () => 'https://img.youtube.com/vi/VIDEO_ID/maxresdefault.jpg',
    );
  }

  // Première appel: génère et cache
  final url1 = getThumbnailWithCache('https://youtube.com/watch?v=abc123');

  // Deuxième appel: utilise le cache (pas de génération)
  final url2 = getThumbnailWithCache('https://youtube.com/watch?v=abc123');

  assert(url1 == url2);
}

// ============================================================================
// EXEMPLE 2: Gestion des Durées de Vidéo
// ============================================================================

void exempleDurees() {
  final cacheManager = VideoCacheManager();

  // Cacher la durée après la récupérer
  void cachVideoInfo(int mediaId, Duration duration) {
    cacheManager.cacheDuration(mediaId, duration);
  }

  // Récupérer depuis le cache si disponible
  Duration? getVideoDurationIfCached(int mediaId) {
    return cacheManager.getCachedDuration(mediaId);
  }

  // Utilisation:
  cachVideoInfo(42, const Duration(minutes: 5, seconds: 30));
  final duration = getVideoDurationIfCached(42);
  print('Durée: ${duration?.inSeconds}s'); // Durée: 330s
}

// ============================================================================
// EXEMPLE 3: Utilisation dans un StatefulWidget
// ============================================================================

class VideoListPageExample extends StatefulWidget {
  final List<VideoInfo> videos;

  const VideoListPageExample({required this.videos});

  @override
  State<VideoListPageExample> createState() => _VideoListPageExampleState();
}

class _VideoListPageExampleState extends State<VideoListPageExample> {
  late VideoCacheManager _cacheManager;

  @override
  void initState() {
    super.initState();
    _cacheManager = VideoCacheManager();
    _preloadAllThumbnails();
  }

  // Preload tous les thumbnails au démarrage
  Future<void> _preloadAllThumbnails() async {
    for (final video in widget.videos) {
      final url = _cacheManager.getThumbnailUrl(
        video.youtubeUrl,
        () => video.getThumbnailUrl(),
      );

      // Image provider pour preload
      if (mounted) {
        precacheImage(NetworkImage(url), context);
      }
    }

    // Afficher les stats
    if (mounted) {
      _cacheManager.printCacheStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.videos.length,
      itemBuilder: (context, index) {
        final video = widget.videos[index];
        final thumbnailUrl = _cacheManager.getThumbnailUrl(
          video.youtubeUrl,
          () => video.getThumbnailUrl(),
        );

        return ListTile(
          leading: Image.network(thumbnailUrl),
          title: Text(video.title),
        );
      },
    );
  }

  @override
  void dispose() {
    // Optionnel: nettoyer le cache lors du logout
    // _cacheManager.clearCacheWithLogging();
    super.dispose();
  }
}

// ============================================================================
// EXEMPLE 4: Diagnostics et Monitoring
// ============================================================================

class CacheMonitoringWidget extends StatefulWidget {
  const CacheMonitoringWidget();

  @override
  State<CacheMonitoringWidget> createState() => _CacheMonitoringWidgetState();
}

class _CacheMonitoringWidgetState extends State<CacheMonitoringWidget> {
  late VideoCacheManager _cacheManager;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _cacheManager = VideoCacheManager();
    _refreshStats();
  }

  void _refreshStats() {
    setState(() {
      _stats = _cacheManager.getCacheStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Cache Thumbnails'),
          trailing: Text('${_stats['thumbnails'] ?? 0}'),
        ),
        ListTile(
          title: const Text('Cache Durations'),
          trailing: Text('${_stats['durations'] ?? 0}'),
        ),
        ListTile(
          title: const Text('Cache Images'),
          trailing: Text('${_stats['images'] ?? 0}'),
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: _refreshStats,
              child: const Text('Rafraîchir'),
            ),
            ElevatedButton(
              onPressed: () {
                _cacheManager.clearCacheWithLogging();
                _refreshStats();
              },
              child: const Text('Vider le Cache'),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// EXEMPLE 5: Gestion du Cycle de Vie
// ============================================================================

class AppLifecycleHandler {
  static final AppLifecycleHandler _instance = AppLifecycleHandler._internal();

  factory AppLifecycleHandler() {
    return _instance;
  }

  AppLifecycleHandler._internal();

  final _cacheManager = VideoCacheManager();

  // Appelé au logout
  void handleLogout() {
    debugPrint('Nettoyage du cache lors du logout...');
    _cacheManager.clearCacheWithLogging();
  }

  // Appelé à la mise en arrière-plan
  void handleAppPaused() {
    final stats = _cacheManager.getCacheStats();
    debugPrint('App paused. Cache stats: $stats');
  }

  // Appelé au retour au premier plan
  void handleAppResumed() {
    debugPrint('App resumed');
  }
}

// ============================================================================
// EXEMPLE 6: Pattern avec Optimisation Mémoire
// ============================================================================

class OptimizedVideoLoader {
  static const int _maxPrefetchVideos = 5;
  final VideoCacheManager _cacheManager = VideoCacheManager();

  // Charger intelligemment les vidéos suivantes
  Future<void> prefetchNextVideos(
    List<VideoInfo> allVideos,
    int currentIndex,
  ) async {
    final endIndex = (currentIndex + _maxPrefetchVideos).clamp(
      0,
      allVideos.length,
    );

    for (int i = currentIndex; i < endIndex; i++) {
      final video = allVideos[i];
      _cacheManager.getThumbnailUrl(
        video.youtubeUrl,
        () => video.getThumbnailUrl(),
      );
    }

    // Nettoyer les old caches si trop gros
    final stats = _cacheManager.getCacheStats();
    if ((stats['thumbnails'] ?? 0) > 50) {
      debugPrint('Cache trop volumineux, nettoyage recommandé');
    }
  }
}

// ============================================================================
// MODÈLES DE DONNÉES
// ============================================================================

class VideoInfo {
  final int id;
  final String title;
  final String youtubeUrl;
  final Duration? cachedDuration;

  VideoInfo({
    required this.id,
    required this.title,
    required this.youtubeUrl,
    this.cachedDuration,
  });

  String getThumbnailUrl() {
    // Implémentation personnalisée
    return 'https://img.youtube.com/vi/$youtubeUrl/maxresdefault.jpg';
  }
}
