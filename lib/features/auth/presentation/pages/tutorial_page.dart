import 'dart:math';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/formation_with_medias.dart';
import 'package:wizi_learn/features/auth/data/models/media_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/media_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/auth_repository.dart';
import 'package:wizi_learn/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:wizi_learn/features/auth/presentation/constants/couleur_palette.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/youtube_player_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/custom_scaffold.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:shared_preferences/shared_preferences.dart';

String normalizeYoutubeUrl(String url) {
  final shortsReg = RegExp(r'youtube\.com/shorts/([\w-]+)');
  final match = shortsReg.firstMatch(url);
  if (match != null && match.groupCount >= 1) {
    final id = match.group(1);
    return 'https://www.youtube.com/watch?v=$id';
  }
  return url;
}

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

    YoutubePlayerController? _currentYoutubeController;


  @override
  void initState() {
    super.initState();
    _initializeDependencies();
    _checkTutorialSeen();
    _loadFormations();
    _loadWatchedMediaIds();
    _checkNotificationNavigation();
  }

  @override
  void dispose() {
    // Nettoyer tous les contrôleurs YouTube
    _youtubeControllers.forEach((_, controller) {
      controller.dispose();
    });
    _youtubeControllers.clear();
    _currentYoutubeController?.dispose();
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
        final Media mediaToOpen = _findMediaToOpen(formations, mediaId);
        final formation = _findFormationForMedia(formations, mediaToOpen);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => YoutubePlayerPage(
              video: _createMediaCopyWithNormalizedUrl(mediaToOpen),
              videosInSameCategory: formation.medias
                  .map(_createMediaCopyWithNormalizedUrl)
                  .toList(),
            ),
          ),
        );
      });
    }
  }

  Media _findMediaToOpen(List<FormationWithMedias> formations, dynamic mediaId) {
    final allMedias = formations.expand((f) => f.medias).toList();
    if (allMedias.isEmpty) throw Exception('Aucun média trouvé');

    if (mediaId != null) {
      return allMedias.firstWhere(
        (m) => m.id.toString() == mediaId.toString(),
        orElse: () => allMedias.first,
      );
    }
    return allMedias.first;
  }

  FormationWithMedias _findFormationForMedia(
    List<FormationWithMedias> formations,
    Media media,
  ) {
    return formations.firstWhere(
      (f) => f.medias.any((m) => m.id == media.id),
      orElse: () => formations.first,
    );
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

  void _updateSelectedMedia(Media media) {
    if (_selectedMedia?.id == media.id) return; // Éviter les mises à jour inutiles

    setState(() {
      _selectedMedia = media;
    });

    // Préparer le contrôleur YouTube pour la nouvelle vidéo
    _prepareYoutubeController(media);
  }

  void _prepareYoutubeController(Media media) {
    final videoId = YoutubePlayer.convertUrlToId(normalizeYoutubeUrl(media.url));
    if (videoId == null) return;

    // Disposer l'ancien contrôleur s'il existe
    _currentYoutubeController?.dispose();

    // Créer un nouveau contrôleur pour la vidéo sélectionnée
    _currentYoutubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true, // Lancer automatiquement la nouvelle vidéo
        mute: false,
        enableCaption: true,
        disableDragSeek: false,
        forceHD: false,
        useHybridComposition: true,
        controlsVisibleAtStart: true,
      ),
    );
  }

  String _filterTitle(String title) {
    return title
        .replaceAll(RegExp(r'microsoft', caseSensitive: false), '')
        .trim();
  }

  String _getRandomThumbnailUrl(String youtubeUrl) {
    final videoId = YoutubePlayer.convertUrlToId(normalizeYoutubeUrl(youtubeUrl));

    if (videoId == null) {
      return YoutubePlayer.getThumbnail(
        videoId: '',
        quality: ThumbnailQuality.medium,
      );
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
        _formationsFuture = stagiaireId != null
            ? _mediaRepository.getFormationsAvecMedias(stagiaireId)
            : Future.value([]);
      });

      // Définir la formation sélectionnée par défaut
      if (_formationsFuture != null) {
        _formationsFuture!.then((list) {
          if (mounted && list.isNotEmpty && _selectedFormationId == null) {
            setState(() {
              _selectedFormationId = list.first.id;
              // Sélectionner automatiquement le premier média sur tablette
              final medias = _getFilteredMedias(list);
              if (medias.isNotEmpty) {
                _updateSelectedMedia(medias.first);
              }
            });
          }
        }).catchError((_) {});
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

      final videoId = YoutubePlayer.convertUrlToId(media.url);
      if (videoId == null) return const Duration(seconds: 0);

      final yt = YoutubeExplode();
      final video = await yt.videos.get('https://www.youtube.com/watch?v=$videoId');
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

  YoutubePlayerController _getYoutubeController(String videoId, int mediaId) {
    if (!_youtubeControllers.containsKey(mediaId)) {
      _youtubeControllers[mediaId] = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          disableDragSeek: false,
          forceHD: false,
          useHybridComposition: true,
          controlsVisibleAtStart: true,
        ),
      );
    }
    return _youtubeControllers[mediaId]!;
  }

  Future<void> _markMediaAsWatched(Media media) async {
    try {
      final resp = await _mediaRepository.markMediaAsWatchedWithResponse(media.id);
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
                            color: i == _tutorialStep ? Colors.orange : Colors.grey[300],
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

  void _showNewBadgesDialog(BuildContext context, List<dynamic> newAchievements) {
    if (newAchievements.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nouveaux Badges !'),
          content: SingleChildScrollView(
            child: ListBody(
              children: newAchievements.map((achievement) {
                return ListTile(
                  leading: const Icon(Icons.emoji_events, color: Colors.amber),
                  title: Text(achievement['name'] ?? 'Badge'),
                  subtitle: Text(achievement['badgeType'] ?? 'Type inconnu'),
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
        if (_fromNotification)
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton.small(
              onPressed: _triggerTutorial,
              tooltip: 'Voir le tutoriel',
              child: const Icon(Icons.help_outline),
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
                  if (medias.isNotEmpty) {
                    _updateSelectedMedia(medias.first);
                  } else {
                    // Si aucun média dans cette catégorie, vider la sélection
                    setState(() {
                      _selectedMedia = null;
                      _currentYoutubeController?.dispose();
                      _currentYoutubeController = null;
                    });
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
        
        return Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.35),
          child: DropdownButton<int>(
            isExpanded: true,
            value: _selectedFormationId ?? items.first.id,
            items: items.map((f) => DropdownMenuItem<int>(
              value: f.id,
              child: Text(f.titre, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (v) {
              setState(() {
                _selectedFormationId = v;
                // Mettre à jour la sélection média quand la formation change
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
        if (_formationsFuture == null || snapshot.connectionState == ConnectionState.waiting) {
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

    final mediasFiltres = selectedFormation.medias
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
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

        if (!isWideLayout) {
          return _buildMobileLayout(mediasFiltres, watchedMediaIds, theme);
        }

        return _buildTabletLayout(mediasFiltres, watchedMediaIds, theme, formations);
      },
    );
  }

  Widget _buildMobileLayout(List<Media> medias, Set<int> watchedMediaIds, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: medias.isEmpty
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
          Flexible(
            flex: 2,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: _buildLeftPanel(medias, watchedMediaIds, theme),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            flex: 3,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildRightPanel(_selectedMedia, medias, formations, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(List<Media> medias, Set<int> watchedMediaIds, ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: medias.isEmpty
                ? _buildNoMediaWidget(theme)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: medias.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
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

    final videoId = YoutubePlayer.convertUrlToId(normalizeYoutubeUrl(selectedMedia.url));
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

  Widget _buildInvalidVideoWidget(Media media, List<Media> medias, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'URL vidéo invalide',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => YoutubePlayerPage(
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

Widget _buildVideoPlayer(Media media, String videoId, List<Media> medias, ThemeData theme) {
    // S'assurer que le contrôleur est prêt
    if (_currentYoutubeController == null) {
      _prepareYoutubeController(media);
    }

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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _currentYoutubeController != null
                  ? YoutubePlayer(
                      controller: _currentYoutubeController!,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: Colors.amber,
                      progressColors: const ProgressBarColors(
                        playedColor: Colors.amber,
                        handleColor: Colors.amberAccent,
                        bufferedColor: Colors.grey,
                      ),
                      bottomActions: [
                        CurrentPosition(),
                        ProgressBar(isExpanded: true),
                        RemainingDuration(),
                        FullScreenButton(
                          controller: _currentYoutubeController!,
                        ),
                      ],
                      onReady: () {
                        debugPrint('Lecteur YouTube prêt pour: ${media.titre}');
                      },
                      onEnded: (data) {
                        _markMediaAsWatched(media);
                        debugPrint('Vidéo terminée: ${media.titre}');
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Chargement du lecteur...'),
                        ],
                      ),
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
                  builder: (_) => YoutubePlayerPage(
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

        return Card(
          elevation: isSelected ? 4 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected 
                ? BorderSide(color: colorScheme.primary, width: 2)
                : BorderSide.none,
          ),
          color: isSelected
              ? colorScheme.primaryContainer
              : (isWatched
                  ? colorScheme.surfaceContainerHighest.withOpacity(0.7)
                  : const Color(0xFFFFF9C4)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _onMediaItemTap(media, isWatched, isTablet),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
              child: Row(
                children: [
                  if (showThumbnail) _buildThumbnail(media, isWatched, duration, theme, isSmallScreen),
                  if (showThumbnail) SizedBox(width: isSmallScreen ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _filterTitle(media.titre),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : (isWatched
                                    ? colorScheme.onSurface.withOpacity(0.7)
                                    : colorScheme.onSurface),
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const LinearProgressIndicator(),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurface.withOpacity(0.6),
                    size: isSmallScreen ? 20 : 24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(Media media, bool isWatched, Duration duration, ThemeData theme, bool isSmallScreen) {
    final videoId = YoutubePlayer.convertUrlToId(media.url);
    final thumbnailUrl = videoId != null ? _getRandomThumbnailUrl(media.url) : null;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: isSmallScreen ? MediaQuery.of(context).size.width * 0.3 : MediaQuery.of(context).size.width * 0.35,
          height: isSmallScreen ? MediaQuery.of(context).size.width * 0.18 : MediaQuery.of(context).size.width * 0.2,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            image: thumbnailUrl != null
                ? DecorationImage(
                    image: NetworkImage(thumbnailUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: thumbnailUrl == null
              ? Icon(
                  Icons.videocam,
                  size: isSmallScreen ? 24 : 32,
                )
              : null,
        ),
        Icon(
          Icons.play_circle_fill,
          size: isSmallScreen ? 28 : 36,
          color: Colors.white.withOpacity(0.8),
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
              child: Icon(
                Icons.check,
                size: isSmallScreen ? 10 : 12,
                color: Colors.white,
              ),
            ),
          ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _formatDuration(duration),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 10 : 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

 Future<void> _onMediaItemTap(Media media, bool isWatched, bool isTablet) async {
    if (!isWatched) {
      final resp = await _mediaRepository.markMediaAsWatchedWithResponse(media.id);
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
      _updateSelectedMedia(media);
    } else {
      // Sur mobile : ouvrir le lecteur dédié (comportement existant)
      final formations = await _formationsFuture;
      if (formations == null || formations.isEmpty) return;

      final selectedFormation = formations.firstWhere(
        (f) => f.id == _selectedFormationId,
        orElse: () => formations.first,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => YoutubePlayerPage(
            video: media,
            videosInSameCategory: selectedFormation.medias
                .where((m) => m.categorie == media.categorie)
                .toList(),
          ),
        ),
      );
    }
  }
}