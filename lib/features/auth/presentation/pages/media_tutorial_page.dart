
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
import 'package:wizi_learn/features/auth/presentation/widgets/video_player_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/custom_scaffold.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class MediaTutorialPage extends StatefulWidget {
  const MediaTutorialPage({super.key});

  @override
  State<MediaTutorialPage> createState() => _MediaTutorialPageState();
}

class _MediaTutorialPageState extends State<MediaTutorialPage> {
  late final MediaRepository _mediaRepository;
  late final AuthRepository _authRepository;

  Future<List<FormationWithMedias>>? _formationsFuture;

  int? _selectedFormationId;
  String _selectedCategory = 'tutoriel';
  bool _fromNotification = false;
  Future<Set<int>>? _watchedMediaIdsFuture;
  bool _showTutorial = false;
  int _tutorialStep = 0;
  bool _isLeftPanelCollapsed = false;
  
  final List<Map<String, String>> _tutorialSteps = [
    {
      'title': 'Bienvenue dans la section Tutoriels !',
      'desc': 'Retrouvez ici des vidéos explicatives et des astuces pour progresser rapidement sur la plateforme.',
    },
    {
      'title': 'Filtrer par catégorie',
      'desc': 'Utilisez les boutons en haut pour basculer entre les tutoriels et les astuces.',
    },
    {
      'title': 'Visionner une vidéo',
      'desc': 'Cliquez sur une vidéo pour l\'ouvrir et la regarder en plein écran.',
    },
    {
      'title': 'Astuce',
      'desc': 'Vous pouvez revenir ici à tout moment pour revoir les tutoriels.',
    },
  ];

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
            builder: (_) => VideoPlayerPage(
              video: mediaToOpen,
              videosInSameCategory: formation.medias,
            ),
          ),
        );
      });
    }
  }

  Media _findMediaToOpen(
    List<FormationWithMedias> formations,
    dynamic mediaId,
  ) {
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

  Future<void> _loadFormations() async {
    try {
      final user = await _authRepository.getMe();
      final stagiaireId = user.stagiaire?.id;

      setState(() {
        _formationsFuture = stagiaireId != null
            ? _mediaRepository.getFormationsAvecMedias(stagiaireId)
            : Future.value([]);
      });

      if (_formationsFuture != null) {
        _formationsFuture!.then((list) {
          if (mounted && list.isNotEmpty && _selectedFormationId == null) {
            setState(() {
              _selectedFormationId = list.first.id;
              final medias = _getFilteredMedias(list);
              if (medias.isNotEmpty) {
                _selectedMedia = medias.first;
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

  Future<void> _checkTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('hasSeenTutorial') ?? false;
    if (!seen && mounted) {
      setState(() {
        _showTutorial = true;
      });
    }
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
              children: newAchievements.map((achievement) {
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
            items: items
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

    final mediasFiltres = selectedFormation.medias
        .where((m) => m.categorie == _selectedCategory)
        .toList();

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
      child: medias.isEmpty
          ? _buildNoMediaWidget(theme)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: medias.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final media = medias[index];
                final isWatched = watchedMediaIds.contains(media.id);
                return _buildMediaCard(
                  context,
                  media,
                  isWatched,
                  theme,
                  medias,
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
            flex: _isLeftPanelCollapsed ? 0 : 2,
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _isLeftPanelCollapsed
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: _buildLeftPanel(medias, watchedMediaIds, theme),
              secondChild: const SizedBox.shrink(),
            ),
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isLeftPanelCollapsed = !_isLeftPanelCollapsed;
                    });
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
              child: _selectedMedia != null
                  ? _buildMediaDetails(_selectedMedia!, theme, medias)
                  : _buildNoMediaWidget(theme),
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
            child: medias.isEmpty
                ? _buildNoMediaWidget(theme)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: medias.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final media = medias[index];
                      final isWatched = watchedMediaIds.contains(media.id);
                      final isSelected = _selectedMedia?.id == media.id;
                      return _buildMediaListItem(
                        media,
                        isWatched,
                        isSelected,
                        theme,
                      );
                    },
                  ),
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

  Widget _buildMediaListItem(
    Media media,
    bool isWatched,
    bool isSelected,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    
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
        borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedMedia = media),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isWatched
                              ? [Colors.grey[300]!, Colors.grey[200]!]
                              : [
                                  colorScheme.primary.withOpacity(0.2),
                                  colorScheme.primary.withOpacity(0.1),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 32,
                        color: isWatched ? colorScheme.primary : Colors.grey,
                      ),
                    ),
                    if (isWatched)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _filterTitle(media.titre),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? colorScheme.primary : null,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildCategoryBadge(media.categorie, isSmall: true),
                          if (media.duree != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${media.duree} min',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              Icons.download_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: () => _downloadMedia(media),
                            tooltip: 'Télécharger',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaCard(
    BuildContext context,
    Media media,
    bool isWatched,
    ThemeData theme,
    List<Media> allMedias,
  ) {
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isWatched
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoPlayerPage(
                      video: media,
                      videosInSameCategory: allMedias,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isWatched
                                  ? [Colors.grey[300]!, Colors.grey[200]!]
                                  : [
                                      colorScheme.primary.withOpacity(0.2),
                                      colorScheme.primary.withOpacity(0.1),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.play_circle_fill,
                            size: 44,
                            color: isWatched ? colorScheme.primary : Colors.grey[400],
                          ),
                        ),
                        if (isWatched)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _filterTitle(media.titre),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildCategoryBadge(media.categorie, isSmall: true),
                              if (media.duree != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 12,
                                        color: Colors.grey[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${media.duree} min',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: IconButton(
              onPressed: () => _downloadMedia(media),
              icon: Icon(
                Icons.download_rounded,
                color: colorScheme.primary,
              ),
              tooltip: 'Télécharger',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaDetails(Media media, ThemeData theme, List<Media> allMedias) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _filterTitle(media.titre),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (media.description != null)
            Expanded(
              child: SingleChildScrollView(
                child: Html(data: media.description!),
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerPage(
                    video: media,
                    videosInSameCategory: allMedias,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Lire la vidéo'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _downloadMedia(media),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Télécharger'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
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
                            color: i == _tutorialStep
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
}
