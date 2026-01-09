import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wizi_learn/features/auth/data/models/media_model.dart';

/// Service de téléchargement et gestion de vidéos hors ligne
class VideoDownloadService {
  final Dio _dio;
  final Map<int, CancelToken> _activeDow nloads = {};
  final Map<int, double> _downloadProgress = {};

  VideoDownloadService(this._dio);

  /// Télécharge une vidéo pour accès hors ligne
  Future<String?> downloadVideo({
    required Media media,
    required String videoUrl,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Obtenir le répertoire de stockage
      final directory = await _getVideosDirectory();
      final fileName = '${media.id}_${_sanitizeFileName(media.titre)}.mp4';
      final filePath = '${directory.path}/$fileName';

      // Vérifier si déjà téléchargé
      if (await File(filePath).exists()) {
        return filePath;
      }

      // Créer un CancelToken pour permettre l'annulation
      final cancelToken = CancelToken();
      _activeDownloads[media.id] = cancelToken;

      // Télécharger le fichier
      await _dio.download(
        videoUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _downloadProgress[media.id] = progress;
            onProgress?.call(progress);
          }
        },
      );

      _activeDownloads.remove(media.id);
      _downloadProgress.remove(media.id);

      return filePath;
    } catch (e) {
      _activeDownloads.remove(media.id);
      _downloadProgress.remove(media.id);
      rethrow;
    }
  }

  /// Annule le téléchargement d'une vidéo
  void cancelDownload(int mediaId) {
    _activeDownloads[mediaId]?.cancel('Téléchargement annulé par l\'utilisateur');
    _activeDownloads.remove(mediaId);
    _downloadProgress.remove(mediaId);
  }

  /// Vérifie si une vidéo est en cours de téléchargement
  bool isDownloading(int mediaId) {
    return _activeDownloads.containsKey(mediaId);
  }

  /// Obtient la progression d'un téléchargement (0.0 à 1.0)
  double? getDownloadProgress(int mediaId) {
    return _downloadProgress[mediaId];
  }

  /// Supprime une vidéo téléchargée
  Future<bool> deleteVideo(int mediaId, String fileName) async {
    try {
      final directory = await _getVideosDirectory();
      final file = File('${directory.path}/$fileName');
      
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Obtient la taille totale des vidéos téléchargées en octets
  Future<int> getTotalStorageUsed() async {
    try {
      final directory = await _getVideosDirectory();
      int totalSize = 0;

      await for (final entity in directory.list()) {
        if (entity is File && entity.path.endsWith('.mp4')) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Liste toutes les vidéos téléchargées
  Future<List<String>> getDownloadedVideos() async {
    try {
      final directory = await _getVideosDirectory();
      final videos = <String>[];

      await for (final entity in directory.list()) {
        if (entity is File && entity.path.endsWith('.mp4')) {
          videos.add(entity.path);
        }
      }

      return videos;
    } catch (e) {
      return [];
    }
  }

  /// Obtient le répertoire de stockage des vidéos
  Future<Directory> _getVideosDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final videosDir = Directory('${appDir.path}/offline_videos');
    
    if (!await videosDir.exists()) {
      await videosDir.create(recursive: true);
    }
    
    return videosDir;
  }

  /// Nettoie le nom de fichier pour le rendre valide
  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}
