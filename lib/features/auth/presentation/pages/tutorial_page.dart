import 'dart:math';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/formation_with_medias_model.dart';
import 'package:wizi_learn/features/auth/data/models/media_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/auth_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/media_repository.dart';
import 'package:wizi_learn/features/auth/data/sources/auth_remote_data_source.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/universal_video_player_page.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:wizi_learn/core/utils/normalize_youtube_url.dart';
import 'package:wizi_learn/core/widgets/custom_scaffold.dart';
import 'package:wizi_learn/core/router/route_constants.dart';
import 'package:wizi_learn/core/theme/app_colors.dart';
import 'package:flutter_html/flutter_html.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  late final MediaRepository _mediaRepository;
  late final AuthRepository _authRepository;

  Future<List<FormationWithMedias>>? _formationsFuture;

  int? _selectedFormationId;
  String _selectedCategory = 'tutoriel';
  bool _fromNotification = false;
  Future<Set<int>>? _watchedMediaIdsFuture;
  final Map<int, Duration> _videoDurationCache = {};
  bool _showTutorial = false;
  int _tutorialStep = 0;
  // Etat pour basculer la liste gauche sur tablette (collapsible sidebar)
  bool _isLeftPanelCollapsed = false;
  final List<Map<String, String>> _tutorialSteps = [
    {
      'title': 'Bienvenue dans la section Tutoriels !',
      'desc':
          'Retrouvez ici des vidéos explicatives et des astuces pour progresser rapidement sur la plateforme.',
    },
    {
      'title': 'Filtrer par catégorie',
      'desc':
          'Utilisez les boutons en haut pour basculer entre les tutoriels et les astuces.',
    },
    {
      'title': 'Visionner une vidéo',
      'desc':
          'Cliquez sur une vidéo pour l\'ouvrir et la regarder en plein écran.',
    },
    {
      'title': 'Astuce',
      'desc':
          'Vous pouvez revenir ici à tout moment pour revoir les tutoriels.',
    },
  ];

  // Contrôleurs YouTube pour éviter les fuites de mémoire
  final Map<int, YoutubePlayerController> _youtubeControllers = {};

  // Nouvelle variable pour suivre la vidéo sélectionnée sur tablette
  Media? _selectedMedia;

  @override
  void initState() {
    super.initState();
    _initializeDependencies();
    // _checkTutorialSeen(); // Désactivé - Affichage manuel uniquement via bouton aide
    _loadFormations();
    _loadWatchedMediaIds();
    _checkNotificationNavigation();
  }

  @override
  void dispose() {
    // Nettoyer tous les contrôleurs YouTube
    _youtubeControllers.forEach((_, controller) {
      controller.close();
    });
    _youtubeControllers.clear();
    super.dispose();
  }

  void _initializeDependencies() {
    final dio = Dio();
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(dio: dio, storage: storage);

    _mediaRepository = MediaRepository(apiClient: apiClient);
    _authRepository = AuthRepository(
      remoteDataSource: AuthRemoteDataSourceImpl(
        apiClient: apiClient,
        storage: storage,
      ),
      storage: storage,
    );
  }

  void _checkNotificationNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args['fromNotification'] == true) {
        setState(() {
          _fromNotification = true;
        });
        _handleNotificationNavigation(args);
      }
    });
  }

  void _handleNotificationNavigation(Map<String, dynamic> args) {
    if (_formationsFuture != null) {
      _formationsFuture!.then((formations) {
        if (formations.isEmpty || !mounted) return;

        final mediaId = args['media_id'] ?? args['mediaId'];
        final Media? mediaToOpen = _findMediaToOpen(formations, mediaId);
        if (mediaToOpen == null) return;
        final formation = _findFormationForMedia(formations, mediaToOpen);
        if (formation == null) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => UniversalVideoPlayerPage(
                  video: _createMediaCopyWithNormalizedUrl(mediaToOpen),
                  videosInSameCategory:
                      formation.medias
                          .map(_createMediaCopyWithNormalizedUrl)
                          .toList(),
                ),
          ),
        );
      });
    }
  }

  Media? _findMediaToOpen(
    List<FormationWithMedias> formations,
    dynamic mediaId,
  ) {
    final allMedias = formations.expand((f) => f.medias).toList();
    if (allMedias.isEmpty) return null;

    if (mediaId != null) {
      return allMedias.firstWhere(
        (m) => m.id.toString() == mediaId.toString(),
      );
    }
    return allMedias.first;
  }

  FormationWithMedias? _findFormationForMedia(
    List<FormationWithMedias> formations,
    Media media,
  ) {
    try {
 return formations.firstWhere(
 (f) => f.medias.any((m) => m.id == media.id),
 );
    } catch (e) {
 return null;
    }
  }

  Media _createMediaCopyWithNormalizedUrl(Media media) {
    return Media(
      id: media.id,
      titre: media.titre,
      description: media.description,
      url: normalizeYoutubeUrl(media.url),
      type: media.type,
      categorie: media.categorie,
      duree: media.duree,
      formationId: media.formationId,
    );
  }

  void _triggerTutorial() {
    setState(() {
      _tutorialStep = 0;
      _showTutorial = true;
    });
  }

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenTutorial', true);

    if (mounted) {
      setState(() {
        _showTutorial = false;
        _tutorialStep = 0;
      });
    }
  }

  String _filterTitle(String title) {
    return title
        .replaceAll(RegExp(r'microsoft', caseSensitive: false), '')
        .trim();
  }

  String? _convertUrlToId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'];
      } else if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.first;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  String _getRandomThumbnailUrl(String youtubeUrl) {
    final videoId = _convertUrlToId(
      normalizeYoutubeUrl(youtubeUrl),
    );

    if (videoId == null) {
      return '';
    }

    final random = Random();
    final randomTimestamp = 30 + random.nextInt(450);
    return 'https://img.youtube.com/vi/$videoId/mqdefault.jpg?t=${randomTimestamp}s';
  }

  Future<void> _loadFormations() async {
    try {
      final user = await _authRepository.getMe();
      final stagiaireId = user.stagiaire?.id;

      setState(() {
        _formationsFuture =
            stagiaireId != null
                ? _mediaRepository.getFormationsAvecMedias(stagiaireId)
                : Future.value([]);
      });

      // Définir la formation sélectionnée par défaut
      if (_formationsFuture != null) {
        _formationsFuture!
            .then((list) {
              if (mounted && list.isNotEmpty && _selectedFormationId == null) {
                setState(() {
                  _selectedFormationId = list.first.id;
                  // Sélectionner automatiquement le premier média sur tablette
                  final medias = _getFilteredMedias(list);
                  if (medias.isNotEmpty) {
                    _selectedMedia = medias.first;
                  }
                });
              }
            })
            .catchError((_) {});
      }
    } catch (e) {
      debugPrint("Erreur chargement formations: $e");
      setState(() {
        _formationsFuture = Future.error(e);
      });
    }
  }

  List<Media> _getFilteredMedias(List<FormationWithMedias> formations) {
    final selectedFormation = formations.firstWhere(
      (f) => f.id == _selectedFormationId,
      orElse: () => formations.first,
    );
    return selectedFormation.medias
        .where((m) => m.categorie == _selectedCategory)
        .toList();
  }

  Future<void> _loadWatchedMediaIds() async {
    try {
      setState(() {
        _watchedMediaIdsFuture = _mediaRepository.getWatchedMediaIds();
      });
    } catch (e) {
      debugPrint("Erreur chargement médias vus: $e");
      setState(() {
        _watchedMediaIdsFuture = Future.value({});
      });
    }
  }

  Future<Duration> _getVideoDuration(Media media) async {
    try {
      if (_videoDurationCache.containsKey(media.id)) {
        return _videoDurationCache[media.id]!;
      }

      if (media.duree != null) {
        final duration = Duration(seconds: media.duree!);
        _videoDurationCache[media.id] = duration;
        return duration;
      }

      final videoId = _convertUrlToId(media.url);
      if (videoId == null) return const Duration(seconds: 0);

      final yt = YoutubeExplode();
      final video = await yt.videos.get(
        'https://www.youtube.com/watch?v=$videoId',
      );
      yt.close();

      final duration = video.duration ?? const Duration(seconds: 0);
      _videoDurationCache[media.id] = duration;
      return duration;
    } catch (e) {
      debugPrint('Erreur récupération durée: $e');
      return const Duration(seconds: 0);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours > 0 ? "$hours:$minutes:$seconds" : "$minutes:$seconds";
  }

  Future<void> _checkTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('hasSeenTutorial') ?? false;
    if (!seen && mounted) {
      setState(() {
        _showTutorial = true;
      });
    }
  }

  YoutubePlayerController _getYoutubeController(String videoId, Media media) {
    if (!_youtubeControllers.containsKey(media.id)) {
      final controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          strictRelatedVideos: true,
          mute: false,
        ),
      );

      controller.listen((event) {
        if (event.playerState == PlayerState.ended) {
          _markMediaAsWatched(media);
          debugPrint('Vidéo terminée: ${media.titre}');
        }
      });

      _youtubeControllers[media.id] = controller;
    }
    return _youtubeControllers[media.id]!;
  }

  Future<void> _markMediaAsWatched(Media media) async {
    try {
      final resp = await _mediaRepository.markMediaAsWatchedWithResponse(
        media.id,
      );
      final success = resp['success'] == true;
      if (success && mounted) {
        _loadWatchedMediaIds();
        final newAchievements = (resp['newAchievements'] as List?) ?? [];
        if (newAchievements.isNotEmpty) {
          _showNewBadgesDialog(context, newAchievements);
        }
      }
    } catch (e) {
      debugPrint('Erreur marquage média comme vu: $e');
    }
  }

  Widget _buildTutorialOverlay(BuildContext context) {
    final step = _tutorialSteps[_tutorialStep];
    return Positioned.fill(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Container(
          key: ValueKey(_tutorialStep),
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      step['title']!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      step['desc']!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_tutorialStep > 0)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _tutorialStep--;
                              });
                            },
                            child: const Text('Précédent'),
                          )
                        else
                          const SizedBox(width: 80),
                        if (_tutorialStep < _tutorialSteps.length - 1)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _tutorialStep++;
                              });
                            },
                            child: const Text('Suivant'),
                          )
                        else
                          ElevatedButton(
                            onPressed: _completeTutorial,
                            child: const Text('Terminer'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_tutorialSteps.length, (i) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color:
                                i == _tutorialStep
                                    ? Colors.orange
                                    : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showNewBadgesDialog(
    BuildContext context,
    List<dynamic> newAchievements,
  ) {
    if (newAchievements.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nouveaux Badges !'),
          content: SingleChildScrollView(
            child: ListBody(
              children:
                  newAchievements.map((achievement) {
                    return ListTile(
                      leading: const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                      ),
                      title: Text(achievement['name'] ?? 'Badge'),
                      subtitle: Text(
                        achievement['badgeType'] ?? 'Type inconnu',
                      ),
                    );
                  }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        _fromNotification
            ? CustomScaffold(
              body: _buildBody(theme),
              currentIndex: 4,
              onTabSelected: (index) {
                Navigator.pushReplacementNamed(
                  context,
                  RouteConstants.dashboard,
                  arguments: index,
                );
              },
              showBanner: true,
            )
            : Scaffold(
              appBar: _buildAppBar(theme, screenWidth),
              body: _buildBody(theme),
            ),
        // Bouton d'aide pour accès rapide au tutoriel
        Positioned(
          right: 16,
          bottom: 24,
          child: FloatingActionButton.small(
            onPressed: _triggerTutorial,
            tooltip: 'Voir le tutoriel',
            backgroundColor: const Color(0xFFFEB823),
            child: const Icon(Icons.help_outline, color: Colors.white),
          ),
        ),
        if (_showTutorial) _buildTutorialOverlay(context),
      ],
    );
  }

  AppBar _buildAppBar(ThemeData theme, double screenWidth) {
    return AppBar(
      backgroundColor: AppColors.background,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCategoryToggle(screenWidth),
          const SizedBox(width: 12),
          _buildFormationSelector(),
        ],
      ),
      elevation: 1,
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          tooltip: 'Voir le tutoriel',
          onPressed: _triggerTutorial,
        ),
      ],
    );
  }

  Widget _buildCategoryToggle(double screenWidth) {
    return Container(
      constraints: BoxConstraints(maxWidth: screenWidth * 0.5),
      child: ToggleButtons(
        isSelected: [
          _selectedCategory == 'tutoriel',
          _selectedCategory == 'astuce',
        ],
        onPressed: (index) {
          setState(() {
            _selectedCategory = index == 0 ? 'tutoriel' : 'astuce';
            // Mettre à jour la sélection média quand la catégorie change
            if (_formationsFuture != null) {
              _formationsFuture!.then((formations) {
                if (mounted && formations.isNotEmpty) {
                  final medias = _getFilteredMedias(formations);
                  if (medias.isNotEmpty && _selectedMedia == null) {
                    _selectedMedia = medias.first;
                  }
                }
              });
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        selectedColor: Colors.white,
        fillColor: const Color(0xFFFEB823),
        color: const Color(0xFF181818),
        constraints: BoxConstraints(
          minHeight: 40,
          minWidth: (screenWidth * 0.5 - 32) / 2,
        ),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 400 ? 16.0 : 8.0,
            ),
            child: const Text('Tutos'),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 400 ? 16.0 : 8.0,
            ),
            child: const Text('Astuces'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormationSelector() {
    return FutureBuilder<List<FormationWithMedias>>(
      future: _formationsFuture,
      builder: (context, snap) {
        final items = snap.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();

        if (items.length <= 1) {
          return const SizedBox.shrink();
        }

        return Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.35,
          ),
          child: DropdownButton<int>(
            isExpanded: true,
            value: _selectedFormationId ?? items.first.id,
            items:
                items
                    .map(
                      (f) => DropdownMenuItem<int>(
                        value: f.id,
                        child: Text(f.titre, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
            onChanged: (v) {
              setState(() {
                _selectedFormationId = v;
                final medias = _getFilteredMedias(items);
                if (medias.isNotEmpty) {
                  _selectedMedia = medias.first;
                }
              });
            },
            underline: const SizedBox(),
          ),
        );
      },
    );
  }

  Widget _buildBody(ThemeData theme) {
    return FutureBuilder<List<FormationWithMedias>>(
      future: _formationsFuture,
      builder: (context, snapshot) {
        if (_formationsFuture == null ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(theme, snapshot.error.toString());
        }

        final formations = snapshot.data ?? [];
        if (formations.isEmpty) {
          return _buildEmptyWidget();
        }

        return _buildContent(formations, theme);
      },
    );
  }

  Widget _buildErrorWidget(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              "Erreur de chargement",
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Détail: $error",
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFormations,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("Aucune formation trouvée."),
      ),
    );
  }

  Widget _buildContent(List<FormationWithMedias> formations, ThemeData theme) {
    final selectedFormation = formations.firstWhere(
      (f) => f.id == _selectedFormationId,
      orElse: () => formations.first,
    );

    final mediasFiltres =
        selectedFormation.medias
            .where((m) => m.categorie == _selectedCategory)
            .toList();

    // Mettre à jour la sélection si nécessaire
    if (_selectedMedia == null && mediasFiltres.isNotEmpty) {
      _selectedMedia = mediasFiltres.first;
    }

    return FutureBuilder<Set<int>>(
      future: _watchedMediaIdsFuture,
      builder: (context, watchedSnapshot) {
        final watchedMediaIds = watchedSnapshot.data ?? {};

        final isWideLayout = MediaQuery.of(context).size.width >= 800;

        if (!isWideLayout) {
          return _buildMobileLayout(mediasFiltres, watchedMediaIds, theme);
        }

        return _buildTabletLayout(
          mediasFiltres,
          watchedMediaIds,
          theme,
          formations,
        );
      },
    );
  }

  Widget _buildMobileLayout(
    List<Media> medias,
    Set<int> watchedMediaIds,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child:
          medias.isEmpty
              ? _buildNoMediaWidget(theme)
              : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: medias.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final media = medias[index];
                  final isWatched = watchedMediaIds.contains(media.id);
                  return _buildMediaItem(
                    context,
                    media,
                    isWatched,
                    theme,
                    theme.colorScheme,
                    true, // showThumbnail
                    isTablet: false, // Mode mobile
                  );
                },
              ),
    );
  }

  Widget _buildTabletLayout(
    List<Media> medias,
    Set<int> watchedMediaIds,
    ThemeData theme,
    List<FormationWithMedias> formations,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          // Left panel: collapsible list of medias
          Flexible(
            flex: _isLeftPanelCollapsed ? 0 : 2,
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState:
                  _isLeftPanelCollapsed
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
              firstChild: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: _buildLeftPanel(medias, watchedMediaIds, theme),
              ),
              secondChild: SizedBox.shrink(),
            ),
          ),
          // Toggle button for collapsing left panel on tablet/landscape
          SizedBox(
            width: 40,
            child: Column(
              children: [
                IconButton(
                  tooltip:
                      _isLeftPanelCollapsed
                          ? 'Afficher la liste'
                          : 'Masquer la liste',
                  onPressed: () {
                    setState(
                      () => _isLeftPanelCollapsed = !_isLeftPanelCollapsed,
                    );
                  },
                  icon: Icon(
                    _isLeftPanelCollapsed ? Icons.menu : Icons.menu_open,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            flex: 3,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildRightPanel(
                _selectedMedia,
                medias,
                formations,
                theme,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(
    List<Media> medias,
    Set<int> watchedMediaIds,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child:
                medias.isEmpty
                    ? _buildNoMediaWidget(theme)
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: medias.length,
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final media = medias[index];
                        final isWatched = watchedMediaIds.contains(media.id);
                        final isSelected = _selectedMedia?.id == media.id;
                        return _buildMediaItem(
                          context,
                          media,
                          isWatched,
                          theme,
                          theme.colorScheme,
                          false, // showThumbnail en mode tablette
                          isTablet: true, // Mode tablette
                          isSelected: isSelected,
                        );
                      },
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel(
    Media? selectedMedia,
    List<Media> medias,
    List<FormationWithMedias> formations,
    ThemeData theme,
  ) {
    if (selectedMedia == null) {
      return _buildNoVideoSelectedWidget(theme);
    }

    final videoId = _convertUrlToId(
      normalizeYoutubeUrl(selectedMedia.url),
    );
    if (videoId == null) {
      return _buildInvalidVideoWidget(selectedMedia, medias, theme);
    }

    return _buildVideoPlayer(selectedMedia, videoId, medias, theme);
  }

  Widget _buildNoMediaWidget(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "Aucun média trouvé",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoVideoSelectedWidget(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Sélectionnez une vidéo',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidVideoWidget(
    Media media,
    List<Media> medias,
    ThemeData theme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('URL vidéo invalide', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => UniversalVideoPlayerPage(
                        video: media,
                        videosInSameCategory: medias,
                      ),
                ),
              );
            },
            child: const Text('Ouvrir dans le lecteur'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(
    Media media,
    String videoId,
    List<Media> medias,
    ThemeData theme,
  ) {
    return Column(
      children: [
        // Titre de la vidéo
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _filterTitle(media.titre),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Lecteur YouTube
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: YoutubePlayer(
                key: ValueKey(media.id),
                controller: _getYoutubeController(videoId, media),
                aspectRatio: 16 / 9,
              ),
            ),
          ),
        ),

        // Description de la vidéo
        if (media.description != null && media.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: SizedBox(
              height: 120,
              child: SingleChildScrollView(
                child: Html(
                  data: media.description,
                  style: {
                    "body": Style(
                      fontSize: FontSize.medium,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  },
                ),
              ),
            ),
          ),

        // Bouton pour ouvrir en plein écran
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => UniversalVideoPlayerPage(
                        video: media,
                        videosInSameCategory: medias,
                      ),
                ),
              );
            },
            icon: const Icon(Icons.fullscreen),
            label: const Text('Ouvrir en plein écran'),
          ),
        ),
      ],
    );
  }

  // Badge catégorie coloré
  Widget _buildCategoryBadge(String category, {bool isSmall = false}) {
    final isAstuce = category == 'astuce';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAstuce
              ? [const Color(0xFFFEB823), const Color(0xFFF59E0B)]
              : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isAstuce ? const Color(0xFFFEB823) : const Color(0xFF3B82F6))
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAstuce ? Icons.lightbulb : Icons.school,
            size: isSmall ? 14 : 16,
            color: Colors.white,
          ),
          SizedBox(width: isSmall ? 3 : 4),
          Text(
            isAstuce ? 'Astuce' : 'Tutoriel',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isSmall ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaItem(
    BuildContext context,
    Media media,
    bool isWatched,
    ThemeData theme,
    ColorScheme colorScheme,
    bool showThumbnail, {
    required bool isTablet,
    bool isSelected = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return FutureBuilder<Duration>(
      future: _getVideoDuration(media),
      builder: (context, snapshot) {
        final duration = snapshot.data ?? const Duration(seconds: 0);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withOpacity(0.8),
                    ]
                  : isWatched
                      ? [
                          Colors.grey[100]!,
                          Colors.grey[50]!,
                        ]
                      : [
                          const Color(0xFFFFFBEA),
                          const Color(0xFFFFF9C4),
                        ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? colorScheme.primary.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                blurRadius: isSelected ? 12 : 8,
                offset: Offset(0, isSelected ? 4 : 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _onMediaItemTap(media, isWatched, isTablet),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 10.0 : 14.0),
                child: Row(
                  children: [
                    if (showThumbnail)
                      _buildThumbnail(
                        media,
                        isWatched,
                        duration,
                        theme,
                        isSmallScreen,
                      ),
                    if (showThumbnail) SizedBox(width: isSmallScreen ? 10 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _filterTitle(media.titre),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? colorScheme.onPrimaryContainer
                                        : (isWatched
                                            ? colorScheme.onSurface
                                                .withOpacity(0.7)
                                            : colorScheme.onSurface),
                                    fontSize: isSmallScreen ? 14 : 16,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildCategoryBadge(
                                media.categorie,
                                isSmall: isSmallScreen,
                              ),
                              const SizedBox(width: 8),
                              if (duration.inSeconds > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: isSmallScreen ? 12 : 14,
                                        color: Colors.grey[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDuration(duration),
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 11 : 12,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: LinearProgressIndicator(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface.withOpacity(0.6),
                            size: isSmallScreen ? 20 : 24,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _downloadMedia(media),
                          icon: Icon(
                            Icons.download_rounded,
                            size: isSmallScreen ? 20 : 24,
                            color: colorScheme.primary,
                          ),
                          tooltip: 'Télécharger',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(
    Media media,
    bool isWatched,
    Duration duration,
    ThemeData theme,
    bool isSmallScreen,
  ) {
    final videoId = _convertUrlToId(media.url);
    final thumbnailUrl =
        videoId != null ? _getRandomThumbnailUrl(media.url) : null;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Container principal de la miniature
        Container(
          width:
              isSmallScreen
                  ? MediaQuery.of(context).size.width * 0.3
                  : (MediaQuery.of(context).size.width >= 800
                      ? 220
                      : MediaQuery.of(context).size.width * 0.35),
          height:
              isSmallScreen
                  ? MediaQuery.of(context).size.width * 0.18
                  : (MediaQuery.of(context).size.width >= 800
                      ? 124
                      : MediaQuery.of(context).size.width * 0.2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image de fond
                if (thumbnailUrl != null)
                  Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.videocam,
                        size: isSmallScreen ? 24 : 32,
                        color: Colors.grey[400],
                      );
                    },
                  )
                else
                  Center(
                    child: Icon(
                      Icons.videocam,
                      size: isSmallScreen ? 24 : 32,
                      color: Colors.grey[400],
                    ),
                  ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Icône play au centre
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.play_arrow,
            size: isSmallScreen ? 20 : 28,
            color: const Color(0xFF3B82F6),
          ),
        ),
        // Badge "vidéo vue" en haut à droite
        if (isWatched)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.check,
                size: isSmallScreen ? 12 : 14,
                color: Colors.white,
              ),
            ),
          ),
        // Badge de durée en bas à droite
        if (duration.inSeconds > 0)
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 6 : 8,
                vertical: isSmallScreen ? 3 : 4,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: isSmallScreen ? 10 : 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 10 : 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _downloadMedia(Media media) async {
    final url = media.url;
    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir le lien')),
        );
      }
    }
  }

  Future<void> _onMediaItemTap(
    Media media,
    bool isWatched,
    bool isTablet,
  ) async {
    if (!isWatched) {
      final resp = await _mediaRepository.markMediaAsWatchedWithResponse(
        media.id,
      );
      final success = resp['success'] == true;
      if (success && mounted) {
        _loadWatchedMediaIds();
        final newAchievements = (resp['newAchievements'] as List?) ?? [];
        if (newAchievements.isNotEmpty) {
          _showNewBadgesDialog(context, newAchievements);
        }
      }
    }

    // Comportement différent selon le device
    if (isTablet) {
      // Sur tablette : mettre à jour la sélection et jouer dans le lecteur intégré
      setState(() {
        _selectedMedia = media;
      });
    } else {
      // Sur mobile : ouvrir le lecteur dédié
      final formations = await _formationsFuture;
      if (formations == null || formations.isEmpty) return;

      final selectedFormation = formations.firstWhere(
        (f) => f.id == _selectedFormationId,
        orElse: () => formations.first,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => UniversalVideoPlayerPage(
                video: media,
                videosInSameCategory:
                    selectedFormation.medias
                        .where((m) => m.categorie == media.categorie)
                        .toList(),
              ),
        ),
      );
    }
  }
}
