import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/formation_model.dart';
import 'package:wizi_learn/features/auth/data/models/media_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/formation_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/media_repository.dart';
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

class _YoutubePlayerPageState extends State<YoutubePlayerPage> {
  late YoutubePlayerController _controller;
  late Media currentVideo;
  bool showPlaylist = true;
  bool _isFullScreen = false;
  final GlobalKey _playerKey = GlobalKey();

  List<Formation> _formations = [];
  bool _isLoadingFormations = true;
  Set<int> _watchedMediaIds = {};
  late MediaRepository _mediaRepository;

  @override
  void initState() {
    super.initState();
    currentVideo = widget.video;
    _initYoutubeController(currentVideo.url);

    // Initialiser le repository
    final dio = Dio();
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(dio: dio, storage: storage);
    _mediaRepository = MediaRepository(apiClient: apiClient);

    // Charger les données
    _loadInitialData();

    // Marquer la vidéo comme vue lorsqu'elle commence à jouer
    _controller.addListener(_onPlayerStateChange);
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadFormations(),
      _loadWatchedMediaIds(),
    ]);
  }

  Future<void> _loadWatchedMediaIds() async {
    try {
      final watchedIds = await _mediaRepository.getWatchedMediaIds();
      setState(() {
        _watchedMediaIds = watchedIds;
      });
    } catch (e) {
      debugPrint('Erreur chargement médias vus: $e');
    }
  }

  void _onPlayerStateChange() {
    if (_controller.value.hasPlayed && !_controller.value.isPlaying) {
      // Marquer comme vu après 5 secondes de visionnage
      if (_controller.value.position.inSeconds >= 5) {
        _markVideoAsWatched();
        _controller.removeListener(_onPlayerStateChange);
      }
    }
  }

  Future<void> _markVideoAsWatched() async {
    try {
      final success = await _mediaRepository.markMediaAsWatched(currentVideo.id);
      if (success) {
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
    setState(() => _isLoadingFormations = true);
    try {
      final apiClient = ApiClient(
        dio: Dio(),
        storage: const FlutterSecureStorage(),
      );
      final repository = FormationRepository(apiClient: apiClient);
      final formations = await repository.getRandomFormations(3);
      setState(() => _formations = formations);
    } catch (e) {
      debugPrint('Error loading formations: $e');
    } finally {
      setState(() => _isLoadingFormations = false);
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
    final videoId = YoutubePlayer.convertUrlToId(normalizedUrl) ?? '';
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        useHybridComposition: true,
        forceHD: true,
      ),
    );
  }

  void _switchVideo(Media media) {
    setState(() {
      currentVideo = media;
      final normalizedUrl = normalizeYoutubeUrl(media.url);
      _controller.load(YoutubePlayer.convertUrlToId(normalizedUrl)!);
      _controller.play();
    });
  }

  void _toggleFullScreen() {
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    setState(() => _isFullScreen = !_isFullScreen);
  }

  void _playerListener() {
    if (_controller.value.isFullScreen != _isFullScreen) {
      setState(() => _isFullScreen = _controller.value.isFullScreen);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _controller.removeListener(_playerListener);
    _controller.removeListener(_onPlayerStateChange);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    _controller.dispose();
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

    final isShort = isYoutubeShort(currentVideo.url);
    final screenHeight = MediaQuery.of(context).size.height;

    // En plein écran
    if (_isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: YoutubePlayerBuilder(
          player: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: colorScheme.primary,
            progressColors: ProgressBarColors(
              playedColor: colorScheme.primary,
              handleColor: colorScheme.primary,
              bufferedColor: colorScheme.surfaceContainerHighest,
              backgroundColor: colorScheme.onSurface.withOpacity(0.2),
            ),
            onReady: () => _controller.addListener(_playerListener),
            onEnded: (_) => _toggleFullScreen(),
            bottomActions: [
              CurrentPosition(),
              ProgressBar(isExpanded: true),
              RemainingDuration(),
              FullScreenButton(
                controller: _controller,
                color: colorScheme.primary,
              ),
            ],
          ),
          builder: (context, player) => SafeArea(
            child: SizedBox.expand(
              child: player,
            ),
          ),
        ),
      );
    }

    // Mode portrait
    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentVideo.titre,
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
            child: GestureDetector(
              key: _playerKey,
              onDoubleTap: _toggleFullScreen,
              child: YoutubePlayerBuilder(
                player: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: colorScheme.primary,
                  progressColors: ProgressBarColors(
                    playedColor: colorScheme.primary,
                    handleColor: colorScheme.primary,
                    bufferedColor: colorScheme.surfaceContainerHighest,
                    backgroundColor: colorScheme.onSurface.withOpacity(0.2),
                  ),
                  onReady: () => _controller.addListener(_playerListener),
                  onEnded: (_) => _isFullScreen ? _toggleFullScreen() : null,
                  bottomActions: [
                    CurrentPosition(),
                    ProgressBar(isExpanded: true),
                    RemainingDuration(),
                    FullScreenButton(
                      controller: _controller,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
                builder: (context, player) => player,
              ),
            ),
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
                    currentVideo.titre,
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

        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected
              ? colorScheme.primary.withOpacity(0.08)
              : isWatched
              ? colorScheme.surfaceVariant.withOpacity(0.5)
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
                      Container(
                        width: screenWidth * 0.2,
                        height: screenWidth * 0.15,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          image: DecorationImage(
                            image: NetworkImage(
                              YoutubePlayer.getThumbnail(
                                videoId: YoutubePlayer.convertUrlToId(media.url) ?? '',
                                quality: ThumbnailQuality.medium,
                              ),
                            ),
                            fit: BoxFit.cover,
                          ),
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
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
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
                          media.titre,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? colorScheme.primary
                                : isWatched
                                ? colorScheme.onSurface.withOpacity(0.7)
                                : null,
                            decoration: isWatched && !isSelected
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
  final Color? linkColor;

  const _ExpandableDescription({
    required this.htmlDescription,
    this.textStyle,
    this.linkColor,
    super.key,
  });

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
