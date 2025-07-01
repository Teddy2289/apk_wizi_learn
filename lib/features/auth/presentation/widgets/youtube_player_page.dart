import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/media_model.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:wizi_learn/features/auth/data/models/formation_model.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/random_formations_widget.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/features/auth/data/repositories/formation_repository.dart';

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

  // Ajout état pour les formations recommandées
  List<Formation> _formations = [];
  bool _isLoadingFormations = true;

  @override
  void initState() {
    super.initState();
    currentVideo = widget.video;
    _initYoutubeController(currentVideo.url);
    _loadFormations();
  }

  Future<void> _loadFormations() async {
    setState(() {
      _isLoadingFormations = true;
    });
    try {
      final apiClient = ApiClient(
        dio: Dio(),
        storage: const FlutterSecureStorage(),
      );
      final repository = FormationRepository(apiClient: apiClient);
      final formations = await repository.getRandomFormations(3);
      setState(() {
        _formations = formations;
        _isLoadingFormations = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFormations = false;
      });
    }
  }

  void _initYoutubeController(String url) {
    final videoId = YoutubePlayer.convertUrlToId(url) ?? '';
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    );
  }

  void _switchVideo(Media media) {
    setState(() {
      currentVideo = media;
      _controller.load(YoutubePlayer.convertUrlToId(media.url)!);
      _controller.play();
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final relatedVideos =
        widget.videosInSameCategory
            .where((v) => v.id != currentVideo.id)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentVideo.titre,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Player YouTube
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              child: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: colorScheme.primary,
                progressColors: ProgressBarColors(
                  playedColor: colorScheme.primary,
                  handleColor: colorScheme.primary,
                  bufferedColor: colorScheme.surfaceContainerHighest,
                  backgroundColor: colorScheme.onSurface.withOpacity(0.2),
                ),
                onReady: () {},
              ),
            ),
          ),
          // Titre de la vidéo + bouton à droite
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    currentVideo.titre,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: (textTheme.titleLarge?.fontSize ?? 20) * 0.7,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    showPlaylist ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      showPlaylist = !showPlaylist;
                    });
                  },
                ),
              ],
            ),
          ),
          // Affichage principal : playlist OU description
          if (showPlaylist)
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: 1 + relatedVideos.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final media =
                      index == 0 ? currentVideo : relatedVideos[index - 1];
                  final isSelected = media.id == currentVideo.id;
                  return Card(
                    elevation: isSelected ? 4 : 1,
                    color:
                        isSelected
                            ? colorScheme.primary.withOpacity(0.08)
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
                      onTap: isSelected ? null : () => _switchVideo(media),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 60,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    YoutubePlayer.getThumbnail(
                                      videoId:
                                          YoutubePlayer.convertUrlToId(
                                            media.url,
                                          ) ??
                                          '',
                                      quality: ThumbnailQuality.medium,
                                    ),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  size: 28,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    media.titre,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color:
                                          isSelected
                                              ? colorScheme.primary
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
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _formatDuration(
                                      _controller.metadata.duration,
                                    ),
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
              ),
            )
          else ...[
            if (currentVideo.description != null)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ExpandableDescription(
                        htmlDescription: currentVideo.description!,
                        textStyle: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Section formations recommandées
                      if (_isLoadingFormations)
                        const Center(child: CircularProgressIndicator())
                      else if (_formations.isNotEmpty)
                        RandomFormationsWidget(
                          formations: _formations,
                          onRefresh: _loadFormations,
                        ),
                    ],
                  ),
                ),
              ),
          ],
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
