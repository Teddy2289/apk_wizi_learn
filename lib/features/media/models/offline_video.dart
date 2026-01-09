/// Modèle pour représenter une vidéo téléchargée
class OfflineVideo {
  final int mediaId;
  final String filePath;
  final String title;
  final int sizeInBytes;
  final DateTime downloadedAt;

  OfflineVideo({
    required this.mediaId,
    required this.filePath,
    required this.title,
    required this.sizeInBytes,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'mediaId': mediaId,
      'filePath': filePath,
      'title': title,
      'sizeInBytes': sizeInBytes,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }

  factory OfflineVideo.fromJson(Map<String, dynamic> json) {
    return OfflineVideo(
      mediaId: json['mediaId'] as int,
      filePath: json['filePath'] as String,
      title: json['title'] as String,
      sizeInBytes: json['sizeInBytes'] as int,
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
    );
  }
}

/// Gestionnaire de stockage des métadonnées de vidéos hors ligne
class OfflineStorageManager {
  static const String _offlineVideosKey = 'offline_videos_metadata';
  final dynamic _cacheService; // CacheService

  OfflineStorageManager(this._cacheService);

  /// Enregistre une vidéo comme téléchargée
  Future<void> saveOfflineVideo(OfflineVideo video) async {
    final videos = await getOfflineVideos();
    
    // Supprimer l'ancienne entrée si elle existe
    videos.removeWhere((v) => v.mediaId == video.mediaId);
    
    // Ajouter la nouvelle
    videos.add(video);
    
    // Sauvegarder
    final videosJson = videos.map((v) => v.toJson()).toList();
    await _cacheService.put(_offlineVideosKey, videosJson);
  }

  /// Récupère toutes les vidéos hors ligne
  Future<List<OfflineVideo>> getOfflineVideos() async {
    final videosJson = _cacheService.get<List>(_offlineVideosKey);
    
    if (videosJson == null) return [];
    
    return videosJson
        .map((json) => OfflineVideo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Vérifie si une vidéo est téléchargée
  Future<bool> isVideoDownloaded(int mediaId) async {
    final videos = await getOfflineVideos();
    return videos.any((v) => v.mediaId == mediaId);
  }

  /// Obtient le chemin local d'une vidéo
  Future<String?> getVideoPath(int mediaId) async {
    final videos = await getOfflineVideos();
    final video = videos.firstWhere(
      (v) => v.mediaId == mediaId,
      orElse: () => OfflineVideo(
        mediaId: -1,
        filePath: '',
        title: '',
        sizeInBytes: 0,
        downloadedAt: DateTime.now(),
      ),
    );
    
    return video.mediaId != -1 ? video.filePath : null;
  }

  /// Supprime les métadonnées d'une vidéo
  Future<void> removeOfflineVideo(int mediaId) async {
    final videos = await getOfflineVideos();
    videos.removeWhere((v) => v.mediaId == mediaId);
    
    final videosJson = videos.map((v) => v.toJson()).toList();
    await _cacheService.put(_offlineVideosKey, videosJson);
  }

  /// Calcule la taille totale en Mo
  Future<double> getTotalSizeMB() async {
    final videos = await getOfflineVideos();
    final totalBytes = videos.fold<int>(
      0,
      (sum, video) => sum + video.sizeInBytes,
    );
    return totalBytes / (1024 * 1024);
  }
}
