import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/media_model.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/youtube_player_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/video_player_page.dart';

/// Détecte le type de vidéo basé sur l'URL
enum VideoType {
  youtube,
  dailymotion,
  selfHosted,
}

/// Lecteur vidéo universel qui détecte automatiquement le type de vidéo
/// et route vers le lecteur approprié (YouTube ou self-hosted)
/// 
/// Similaire à UniversalVideoPlayer.tsx dans React
class UniversalVideoPlayerPage extends StatelessWidget {
  final Media video;
  final List<Media> videosInSameCategory;

  const UniversalVideoPlayerPage({
    super.key,
    required this.video,
    required this.videosInSameCategory,
  });

  /// Détecte le type de vidéo en analysant l'URL
  VideoType _detectVideoType(String url) {
    if (url.isEmpty) return VideoType.selfHosted;

    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();

      // Détection YouTube
      if (host.contains('youtube.com') || 
          host.contains('youtu.be') || 
          url.contains('youtube.com/shorts/')) {
        return VideoType.youtube;
      }

      // Détection Dailymotion
      if (host.contains('dailymotion.com') || host.contains('dai.ly')) {
        return VideoType.dailymotion;
      }

      // Si l'URL est relative (pas de host) ou pointe vers notre serveur → self-hosted
      if (host.isEmpty || 
          url.startsWith('/') || 
          url.startsWith('uploads/') ||
          url.contains('/api/media/')) {
        return VideoType.selfHosted;
      }

      // Par défaut, traiter comme self-hosted
      return VideoType.selfHosted;
    } catch (e) {
      // En cas d'erreur de parsing, considérer comme self-hosted
      debugPrint('Erreur parsing URL: $e');
      return VideoType.selfHosted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoType = _detectVideoType(video.url);

    debugPrint('🎬 UniversalVideoPlayer: ${video.titre}');
    debugPrint('   URL: ${video.url}');
    debugPrint('   Type détecté: $videoType');

    switch (videoType) {
      case VideoType.youtube:
        return YoutubePlayerPage(
          video: video,
          videosInSameCategory: videosInSameCategory,
        );

      case VideoType.dailymotion:
        // Pour Dailymotion, utiliser le lecteur self-hosted
        // (Chewie peut lire les iframes Dailymotion ou on peut ajouter un package spécifique)
        return VideoPlayerPage(
          video: video,
          videosInSameCategory: videosInSameCategory,
        );

      case VideoType.selfHosted:
      default:
        return VideoPlayerPage(
          video: video,
          videosInSameCategory: videosInSameCategory,
        );
    }
  }
}
