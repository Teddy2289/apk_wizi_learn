import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/features/auth/data/models/media_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/media_repository.dart';
import 'package:flutter_html/flutter_html.dart';

class VideoPlayerPage extends StatefulWidget {
  final Media video;
  final List<Media> videosInSameCategory;

  const VideoPlayerPage({
    super.key,
    required this.video,
    required this.videosInSameCategory,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

String _filterTitle(String title) {
  return title.replaceAll(RegExp(r'microsoft', caseSensitive: false), '').trim();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  late Media currentVideo;
  bool showPlaylist = true;
  bool _isLoading = true;
  Set<int> _watchedMediaIds = {};
  late MediaRepository _mediaRepository;
  
  // Zoom and Orientation state
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;
  BoxFit _fitMode = BoxFit.contain;

  @override
  void initState() {
    super.initState();
    currentVideo = widget.video;

    // Initialize repository
    final dio = Dio();
    const storage = FlutterSecureStorage();
    _mediaRepository = MediaRepository(apiClient: ApiClient(dio: dio, storage: storage));

    _initializeVideoPlayer(currentVideo);
    
    _transformationController.addListener(() {
      if (mounted) {
        setState(() {
          _currentScale = _transformationController.value.getMaxScaleOnAxis();
        });
      }
    });

    Future.microtask(() {
      _loadWatchedMediaIds();
    });
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

  Future<void> _initializeVideoPlayer(Media media) async {
    setState(() => _isLoading = true);

    try {
      // Dispose old controllers
      if (_chewieController != null) {
        await _chewieController!.pause();
        _chewieController!.dispose();
        _chewieController = null;
      }
      if (_videoPlayerController != null) {
        _videoPlayerController!.dispose();
        _videoPlayerController = null;
      }


      // Get video URL - use baseUrlImg for media files, not baseUrl (which includes /api)
      const baseUrl = AppConstants.baseUrlImg;
      
      // Use getMediaUrl for safe concatenation
      String videoUrl;
      if (media.videoUrl != null && media.videoUrl!.isNotEmpty) {
        // Backend provides video_url like "/api/media/stream/uploads/medias/1764409630.mp4"
        videoUrl = AppConstants.getMediaUrl(media.videoUrl!);
      } else {
        // Fallback: construct URL manually
        if (media.url.startsWith('http')) {
          videoUrl = media.url;
        } else if (media.url.startsWith('/api/')) {
          videoUrl = AppConstants.getMediaUrl(media.url);
        } else {
          // Need to add /api/media/stream/ prefix if it's just a file path
          videoUrl = AppConstants.getAudioStreamUrl(media.url);
        }
      }

      debugPrint('Loading video: $videoUrl');

      // Initialize video player controller with caching for 'astuces'
      final videoPlayerOptions = VideoPlayerOptions(
        allowBackgroundPlayback: false,
        mixWithOthers: true,
      );

      if (media.categorie == 'astuce') {
        final cacheManager = DefaultCacheManager();
        final fileInfo = await cacheManager.getFileFromCache(videoUrl);
        
        if (fileInfo != null) {
          debugPrint('Playing from cache: $videoUrl');
          _videoPlayerController = VideoPlayerController.file(
            fileInfo.file,
            videoPlayerOptions: videoPlayerOptions,
          );
        } else {
          debugPrint('Playing from network and caching: $videoUrl');
          _videoPlayerController = VideoPlayerController.networkUrl(
            Uri.parse(videoUrl),
            videoPlayerOptions: videoPlayerOptions,
            httpHeaders: {
              'Accept': 'video/mp4,video/*',
            },
          );
          // Start background caching
          cacheManager.downloadFile(videoUrl).then((_) {
            debugPrint('Video cached successfully: $videoUrl');
          }).catchError((e) {
            debugPrint('Failed to cache video: $e');
          });
        }
      } else {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
          videoPlayerOptions: videoPlayerOptions,
          httpHeaders: {
            'Accept': 'video/mp4,video/*',
          },
        );
      }

      await _videoPlayerController!.initialize();

      // Initialize Chewie controller with enhanced options
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        playbackSpeeds: [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0],
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Erreur de lecture vidéo',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).colorScheme.primary,
          handleColor: Theme.of(context).colorScheme.primary,
          bufferedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],
        deviceOrientationsOnEnterFullScreen: [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],
        locale: const Locale('fr', 'FR'),
      );

      // Listen for video progress to mark as watched
      _videoPlayerController!.addListener(_videoListener);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        // Use post-frame callback to show snackbar after build is complete
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur de chargement de la vidéo: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    }
  }

  void _videoListener() {
    if (_videoPlayerController == null || !_videoPlayerController!.value.isInitialized) return;
    
    final position = _videoPlayerController!.value.position;
    if (position.inSeconds >= 5 && !_watchedMediaIds.contains(currentVideo.id)) {
      _markVideoAsWatched();
    }
  }

  Future<void> _markVideoAsWatched() async {
    if (_watchedMediaIds.contains(currentVideo.id)) return;
    
    try {
      final success = await _mediaRepository.markMediaAsWatched(currentVideo.id);
      if (success && mounted) {
        setState(() {
          _watchedMediaIds.add(currentVideo.id);
        });
        debugPrint('Vidéo marquée comme vue avec succès');
      }
    } catch (e) {
      debugPrint('Erreur lors du marquage: $e');
    }
  }

  void _switchVideo(Media media) {
    if (currentVideo.id == media.id) return;

    setState(() {
      currentVideo = media;
    });
    
    _initializeVideoPlayer(media);
  }

  @override
  void dispose() {
    _videoPlayerController?.removeListener(_videoListener);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    final relatedVideos = widget.videosInSameCategory
        .where((v) => v.id != currentVideo.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _filterTitle(currentVideo.titre),
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
          // Video Player
          AspectRatio(
            aspectRatio: _videoPlayerController != null && _videoPlayerController!.value.isInitialized
                ? _videoPlayerController!.value.aspectRatio
                : 16 / 9,
            child: Container(
              color: Colors.black,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _chewieController != null
                      ? Stack(
                          children: [
                            Positioned.fill(
                              child: InteractiveViewer(
                                transformationController: _transformationController,
                                minScale: 1.0,
                                maxScale: 5.0,
                                boundaryMargin: const EdgeInsets.all(20),
                                child: Center(
                                  child: FittedBox(
                                    fit: _fitMode,
                                    child: SizedBox(
                                      width: _videoPlayerController!.value.size.width,
                                      height: _videoPlayerController!.value.size.height,
                                      child: Chewie(controller: _chewieController!),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Material(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _fitMode = _fitMode == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _fitMode == BoxFit.cover ? Icons.fullscreen_exit : Icons.fullscreen,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _fitMode == BoxFit.cover ? 'ADAPTER' : 'REMPLIR',
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_currentScale > 1.1)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Material(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    onTap: () {
                                      _transformationController.value = Matrix4.identity();
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.zoom_out_map, color: Colors.white, size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            'Réinitialiser zoom',
                                            style: TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : const Center(
                          child: Text(
                            'Erreur de chargement',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
            ),
          ),

          // Video Title and Playlist Toggle
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenWidth * 0.03,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _filterTitle(currentVideo.titre),
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
                  onPressed: () => setState(() => showPlaylist = !showPlaylist),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Playlist or Description
          Expanded(
            child: showPlaylist
                ? _buildPlaylist(relatedVideos, colorScheme, textTheme, screenWidth)
                : _buildDescription(context, colorScheme, textTheme),
          ),
        ],
      ),
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
        final filteredTitle = _filterTitle(media.titre);

        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected
              ? colorScheme.primary.withOpacity(0.08)
              : isWatched
                  ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
                  : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isSelected
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
                      Container(
                        width: screenWidth * 0.2,
                        height: screenWidth * 0.15,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            size: screenWidth * 0.07,
                            color: isWatched
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
                          filteredTitle,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? colorScheme.primary
                                : isWatched
                                    ? colorScheme.onSurface.withOpacity(0.7)
                                    : null,
                            // decoration: isWatched && !isSelected
                            //     ? TextDecoration.lineThrough
                            //     : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
            Html(
              data: currentVideo.description!,
              style: {
                "body": Style(
                  fontSize: FontSize(14),
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              },
            ),
        ],
      ),
    );
  }
}
