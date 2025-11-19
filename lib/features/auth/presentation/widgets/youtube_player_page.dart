import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wizi_learn/core/video/video_fullscreen_helper.dart';
import 'package:wizi_learn/core/video/video_cache_manager.dart';
import 'package:wizi_learn/core/video/fullscreen_video_player.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/formation_model.dart';
import 'package:wizi_learn/features/auth/data/models/media_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/formation_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/media_repository.dart';
import 'package:wizi_learn/features/auth/presentation/pages/tutorial_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/random_formations_widget.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_html/flutter_html.dart';

class YoutubePlayerPage extends StatefulWidget {
  final Media video;
  final List<Media> videosInSameCategory;

  const YoutubePlayerPage({
    super.key,
    required this.video,
    required this.videosInSameCategory,
  });

  @override
  State<YoutubePlayerPage> createState() => _YoutubePlayerPageState();
}

String _filterTitle(String title) {
  // Supprimer le mot Microsoft (insensible à la casse)
  return title
      .replaceAll(RegExp(r'microsoft', caseSensitive: false), '')
      .trim();
}

String _getRandomThumbnailUrl(String youtubeUrl) {
  final cacheManager = VideoCacheManager();

  return cacheManager.getThumbnailUrl(youtubeUrl, () {
    final videoId = YoutubePlayer.convertUrlToId(
      normalizeYoutubeUrl(youtubeUrl),
    );

    if (videoId == null) {
      return YoutubePlayer.getThumbnail(
        videoId: '',
        quality: ThumbnailQuality.medium,
      );
    }

    // Générer un timestamp aléatoire entre 30 secondes et 8 minutes
    // pour éviter les thumbnails du début
    final random = Random();
    final randomTimestamp = 30 + random.nextInt(450); // 30s à 480s (8min)

    // Utiliser l'URL avec timestamp pour un extrait aléatoire
    return 'https://img.youtube.com/vi/$videoId/mqdefault.jpg?t=${randomTimestamp}s';
  });
}

class _YoutubePlayerPageState extends State<YoutubePlayerPage> {
  late YoutubePlayerController _controller;
  late Media currentVideo;
  bool showPlaylist = true;
  List<Formation> _formations = [];
  bool _isLoadingFormations = true;
  Set<int> _watchedMediaIds = {};
  late MediaRepository _mediaRepository;
  late VideoCacheManager _cacheManager;

  @override
  void initState() {
    super.initState();
    currentVideo = widget.video;
    _cacheManager = VideoCacheManager();
    _initYoutubeController(currentVideo.url);

    // Initialiser le repository
    final dio = Dio();
    const storage = FlutterSecureStorage();
    _mediaRepository = MediaRepository(
      apiClient: ApiClient(dio: dio, storage: storage),
    );

    // Délayer les opérations non critiques
    Future.microtask(() {
      _loadWatchedMediaIds();
      if (mounted) _preloadThumbnails(widget.videosInSameCategory);
    });
    Future.delayed(const Duration(seconds: 2), _loadFormations);

    _controller.addListener(_onPlayerStateChange);
  }

  Future<void> _preloadThumbnails(List<Media> videos) async {
    for (final video in videos) {
      final videoId = YoutubePlayer.convertUrlToId(
        normalizeYoutubeUrl(video.url),
      );
      if (videoId != null) {
        final thumbnailUrl = _getRandomThumbnailUrl(video.url);
        final imageProvider = NetworkImage(thumbnailUrl);

        // Cache l'image pour un chargement rapide ultérieur
        _cacheManager.cacheImage(thumbnailUrl, imageProvider);

        // Précache aussi l'image dans le système Flutter
        if (mounted) {
          precacheImage(imageProvider, context);
        }
      }
    }
  }

  Future<void> _loadWatchedMediaIds() async {
    try {
      final watchedIds = await _mediaRepository.getWatchedMediaIds();
      if (mounted) {
        setState(() {
          _watchedMediaIds = watchedIds;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement médias vus: $e');
    }
  }

  void _onPlayerStateChange() {
    if (_controller.value.playerState == PlayerState.playing &&
        _controller.value.position.inSeconds >= 5) {
      _markVideoAsWatched();
      _controller.removeListener(_onPlayerStateChange);
    }
  }

  Future<void> _markVideoAsWatched() async {
    try {
      final success = await _mediaRepository.markMediaAsWatched(
        currentVideo.id,
      );
      if (success && mounted) {
        setState(() {
          _watchedMediaIds.add(currentVideo.id);
        });
        debugPrint('Vidéo marquée comme vue avec succès');
      } else {
        debugPrint('Échec du marquage de la vidéo comme vue');
      }
    } catch (e) {
      debugPrint('Erreur lors du marquage: $e');
    }
  }

  Future<void> _loadFormations() async {
    if (!mounted) return;

    setState(() => _isLoadingFormations = true);
    try {
      final apiClient = ApiClient(
        dio: Dio(),
        storage: const FlutterSecureStorage(),
      );
      final repository = FormationRepository(apiClient: apiClient);
      final formations = await repository.getRandomFormations(3);
      if (mounted) {
        setState(() => _formations = formations);
      }
    } catch (e) {
      debugPrint('Error loading formations: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingFormations = false);
      }
    }
  }

  String normalizeYoutubeUrl(String url) {
    final shortsReg = RegExp(r'youtube\.com/shorts/([\w-]+)');
    final match = shortsReg.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      final id = match.group(1);
      return 'https://www.youtube.com/watch?v=$id';
    }
    return url;
  }

  bool isYoutubeShort(String url) {
    return url.contains('youtube.com/shorts/');
  }

  void _initYoutubeController(String url) {
    final normalizedUrl = normalizeYoutubeUrl(url);
    final videoId = YoutubePlayer.convertUrlToId(normalizedUrl);

    if (videoId == null || videoId.isEmpty) {
      debugPrint('Invalid YouTube URL: $url');
      return;
    }

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        disableDragSeek: true,
        forceHD: false,
        useHybridComposition: true,
      ),
    );

    // Ajoutez un listener pour les erreurs
    _controller.addListener(() {
      if (_controller.value.hasError) {
        debugPrint('YouTube Player Error: ${_controller.value.errorCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erreur de lecture: ${_controller.value.errorCode}',
              ),
            ),
          );
        }
      }
    });
  }

  void _switchVideo(Media media) {
    if (currentVideo.id == media.id)
      return; // Ne rien faire si c'est la même vidéo

    final normalizedUrl = normalizeYoutubeUrl(media.url);
    final videoId = YoutubePlayer.convertUrlToId(normalizedUrl);
    if (videoId == null) {
      debugPrint('Invalid YouTube URL: ${media.url}');
      return;
    }

    // Marquer l'ancienne vidéo comme vue avant de changer
    _markVideoAsWatched();

    // Mettre à jour l'état et charger la nouvelle vidéo
    setState(() {
      currentVideo = media;
      // Utiliser `load` pour une transition plus rapide si la vidéo n'est pas déjà
      // en mémoire tampon, ou `cue` pour la préparer
      _controller.load(videoId);
      // Le `load` démarre la lecture automatiquement avec autoPlay:true
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.removeListener(_onPlayerStateChange);
    _controller.dispose();
    // Ensure orientation is restored when leaving the player
    VideoFullscreenHelper.exitLandscape();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    final relatedVideos =
        widget.videosInSameCategory
            .where((v) => v.id != currentVideo.id)
            .toList();

    // Utilisation de YoutubePlayerBuilder pour gérer automatiquement le plein écran
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: colorScheme.primary,
        progressColors: ProgressBarColors(
          playedColor: colorScheme.primary,
          handleColor: colorScheme.primary,
        ),
        // Contrôles personnalisés avec meilleure visibilité
        bottomActions: [
          CurrentPosition(),
          ProgressBar(
            isExpanded: true,
            colors: ProgressBarColors(
              playedColor: colorScheme.primary,
              handleColor: colorScheme.primary,
              bufferedColor: Colors.white24,
              backgroundColor: Colors.white10,
            ),
          ),
          RemainingDuration(),
          // Bouton fullscreen avec taille augmentée
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: FullScreenButton(
              controller: _controller,
              color: Colors.white,
            ),
          ),
        ],
      ),
      builder: (context, player) {
        // Ensure orientation helper runs after each build so we can
        // enter/exit landscape mode when the UI switches to fullscreen.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (MediaQuery.of(context).orientation == Orientation.landscape) {
            VideoFullscreenHelper.enterLandscape();
          } else {
            VideoFullscreenHelper.exitLandscape();
          }
        });

        // En mode paysage, on utilise le lecteur fullscreen avec zoom
        if (MediaQuery.of(context).orientation == Orientation.landscape) {
          return FullscreenVideoPlayer(
            controller: _controller,
            playerWidget: player,
          );
        }

        // En mode portrait, on affiche l'interface complète
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _filterTitle(currentVideo.titre), // FILTRE APPLIQUÉ
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: screenWidth * 0.045,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            centerTitle: true,
            elevation: 0,
          ),
          body: Column(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: player, // Utilisation du widget 'player'
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenWidth * 0.03,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _filterTitle(currentVideo.titre), // FILTRE APPLIQUÉ
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.04,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        showPlaylist ? Icons.expand_less : Icons.expand_more,
                      ),
                      onPressed:
                          () => setState(() => showPlaylist = !showPlaylist),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    showPlaylist
                        ? _buildPlaylist(
                          relatedVideos,
                          colorScheme,
                          textTheme,
                          screenWidth,
                        )
                        : _buildDescription(context, colorScheme, textTheme),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaylist(
    List<Media> relatedVideos,
    ColorScheme colorScheme,
    TextTheme textTheme,
    double screenWidth,
  ) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      physics: const BouncingScrollPhysics(),
      itemCount: 1 + relatedVideos.length,
      separatorBuilder: (_, __) => SizedBox(height: screenWidth * 0.02),
      itemBuilder: (context, index) {
        final media = index == 0 ? currentVideo : relatedVideos[index - 1];
        final isSelected = media.id == currentVideo.id;
        final isWatched = _watchedMediaIds.contains(media.id);

        // Filtrer le titre
        final filteredTitle = _filterTitle(media.titre);

        return Card(
          elevation: isSelected ? 4 : 1,
          color:
              isSelected
                  ? colorScheme.primary.withOpacity(0.08)
                  : isWatched
                  ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
                  : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side:
                isSelected
                    ? BorderSide(color: colorScheme.primary, width: 2)
                    : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _switchVideo(media),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.03),
              child: Row(
                children: [
                  Stack(
                    children: [
                      // Thumbnail avec timestamp aléatoire (pas du début)
                      Container(
                        width: screenWidth * 0.2,
                        height: screenWidth * 0.15,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          image: DecorationImage(
                            image: NetworkImage(
                              _getRandomThumbnailUrl(media.url),
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            size: screenWidth * 0.07,
                            color:
                                isWatched
                                    ? colorScheme.primary
                                    : Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                      if (isWatched)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          filteredTitle, // Utiliser le titre filtré
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color:
                                isSelected
                                    ? colorScheme.primary
                                    : isWatched
                                    ? colorScheme.onSurface.withOpacity(0.7)
                                    : null,
                            decoration:
                                isWatched && !isSelected
                                    ? TextDecoration.underline
                                    : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Padding(
                      padding: EdgeInsets.only(left: screenWidth * 0.02),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.015,
                          vertical: screenWidth * 0.005,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(_controller.metadata.duration),
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDescription(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentVideo.description != null)
            _ExpandableDescription(
              htmlDescription: currentVideo.description!,
              textStyle: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          const SizedBox(height: 24),
          if (_isLoadingFormations)
            const Center(child: CircularProgressIndicator())
          else if (_formations.isNotEmpty)
            RandomFormationsWidget(
              formations: _formations,
              onRefresh: _loadFormations,
            ),
        ],
      ),
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  final String htmlDescription;
  final TextStyle? textStyle;

  const _ExpandableDescription({required this.htmlDescription, this.textStyle});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Html(
            data: widget.htmlDescription,
            style: {
              "body": Style(
                maxLines: 3,
                textOverflow: TextOverflow.ellipsis,
                fontSize: FontSize(widget.textStyle?.fontSize ?? 14),
                color: widget.textStyle?.color,
                fontFamily: widget.textStyle?.fontFamily,
              ),
            },
          ),
          secondChild: Html(
            data: widget.htmlDescription,
            style: {
              "body": Style(
                fontSize: FontSize(widget.textStyle?.fontSize ?? 14),
                color: widget.textStyle?.color,
                fontFamily: widget.textStyle?.fontFamily,
              ),
            },
          ),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => expanded = !expanded),
            child: Text(expanded ? 'Afficher moins' : 'Afficher plus'),
          ),
        ),
      ],
    );
  }
}
