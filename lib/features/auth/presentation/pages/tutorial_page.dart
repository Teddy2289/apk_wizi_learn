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
          'Cliquez sur une vidéo pour l’ouvrir et la regarder en plein écran.',
    },
    {
      'title': 'Astuce',
      'desc':
          'Vous pouvez revenir ici à tout moment pour revoir les tutoriels.',
    },
  ];

  void _triggerTutorial() {
    setState(() {
      _tutorialStep = 0;
      _showTutorial = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkTutorialSeen();
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

    _loadFormations();
    _loadWatchedMediaIds();

    // Vérifier si on vient d'une notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args['fromNotification'] == true) {
        setState(() {
          _fromNotification = true;
        });
        final mediaId = args['media_id'] ?? args['mediaId'];
        if (_formationsFuture != null) {
          _formationsFuture!.then((formations) {
            Media mediaToOpen;
            List<Media> allMedias = [];
            for (final formation in formations) {
              allMedias.addAll(formation.medias);
            }
            if (allMedias.isEmpty) return;
            if (mediaId != null) {
              mediaToOpen = allMedias.firstWhere(
                (m) => m.id.toString() == mediaId.toString(),
                orElse: () => allMedias.first,
              );
            } else {
              mediaToOpen = allMedias.first;
            }
            // Trouver la formation correspondante pour la playlist
            final formation = formations.firstWhere(
              (f) => f.medias.any((m) => m.id == mediaToOpen.id),
              orElse: () => formations.first,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => YoutubePlayerPage(
                      video: Media(
                        id: mediaToOpen.id,
                        titre: mediaToOpen.titre,
                        description: mediaToOpen.description,
                        url: normalizeYoutubeUrl(mediaToOpen.url),
                        type: mediaToOpen.type,
                        categorie: mediaToOpen.categorie,
                        duree: mediaToOpen.duree,
                        formationId: mediaToOpen.formationId,
                      ),
                      videosInSameCategory:
                          formation.medias
                              .map(
                                (m) => Media(
                                  id: m.id,
                                  titre: m.titre,
                                  description: m.description,
                                  url: normalizeYoutubeUrl(m.url),
                                  type: m.type,
                                  categorie: m.categorie,
                                  duree: m.duree,
                                  formationId: m.formationId,
                                ),
                              )
                              .toList(),
                    ),
              ),
            );
          });
        }
      }
    });
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
      // After the future resolves, ensure a default selected formation id is set
      if (_formationsFuture != null) {
        _formationsFuture!.then((list) {
          if (list.isNotEmpty && _selectedFormationId == null) {
            setState(() {
              _selectedFormationId = list.first.id;
            });
          }
        }).catchError((_) {});
      }
    } catch (e) {
      debugPrint("Erreur : $e");
      setState(() {
        _formationsFuture = Future.error(e);
      });
    }
  }

  Future<void> _loadWatchedMediaIds() async {
    try {
      setState(() {
        _watchedMediaIdsFuture = _mediaRepository.getWatchedMediaIds();
      });
    } catch (e) {
      debugPrint("Erreur lors du chargement des médias vus: $e");
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
    if (!seen) {
      setState(() {
        _showTutorial = true;
      });
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
                      style: Theme.of(context).textTheme.titleLarge,
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
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('hasSeenTutorial', true);
                              setState(() {
                                _showTutorial = false;
                              });
                            },
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
                    return Text(
                      '${achievement['name']} (${achievement['badgeType']})',
                    );
                  }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final body = FutureBuilder<List<FormationWithMedias>>(
      future: _formationsFuture,
      builder: (context, snapshot) {
        if (_formationsFuture == null ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
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
                    "Détail: ${snapshot.error}",
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

        final formations = snapshot.data ?? [];

        if (formations.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Aucune formation trouvée."),
            ),
          );
        }

        final selectedFormation = formations.firstWhere(
          (f) => f.id == _selectedFormationId,
          orElse: () => formations.first,
        );

        final mediasFiltres =
            selectedFormation.medias
                .where((m) => m.categorie == _selectedCategory)
                .toList();

        return FutureBuilder<Set<int>>(
          future: _watchedMediaIdsFuture,
          builder: (context, watchedSnapshot) {
            final watchedMediaIds = watchedSnapshot.data ?? {};

            // Responsive: colonne sur mobile, layout en deux panneaux sur écrans larges
            final isWideLayout = MediaQuery.of(context).size.width >= 800;

            // Widget du sélecteur + liste (réutilisable pour les deux modes)
            Widget leftPanel() {
              return Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: mediasFiltres.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.video_library_outlined,
                                    size: 64,
                                    color: colorScheme.onSurface.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Aucun média trouvé",
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              itemCount: mediasFiltres.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final media = mediasFiltres[index];
                                final isWatched = watchedMediaIds.contains(
                                  media.id,
                                );
                                return _buildMediaItem(
                                  context,
                                  media,
                                  isWatched,
                                  theme,
                                  colorScheme,
                                );
                              },
                            ),
                    ),
                  ),
                ],
              );
            }

            if (!isWideLayout) {
              // Mode mobile / portrait : comportement inchangé
              return leftPanel();
            }

            // Mode tablette / paysage : deux panneaux
            final selectedMedia = mediasFiltres.isNotEmpty
                ? mediasFiltres.firstWhere(
                    (m) => m.id == (_selectedFormationId == null
                        ? mediasFiltres.first.id
                        : _selectedFormationId),
                    orElse: () => mediasFiltres.first,
                  )
                : null;

            Widget rightPanel() {
              if (selectedMedia == null) {
                return Center(
                  child: Text('Aucun média sélectionné', style: theme.textTheme.bodyMedium),
                );
              }

              final videoId = YoutubePlayer.convertUrlToId(selectedMedia.url);
              final thumbnailUrl = videoId != null
                  ? YoutubePlayer.getThumbnail(videoId: videoId, quality: ThumbnailQuality.medium)
                  : null;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vignette + play
                    if (thumbnailUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(thumbnailUrl, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Icon(Icons.videocam, size: 48)),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      selectedMedia.titre,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedMedia.description ?? '',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Ouvre le lecteur plein écran
                        final formationsAll = await _formationsFuture;
                        if (formationsAll == null || formationsAll.isEmpty) return;
                        final parentFormation = formationsAll.firstWhere(
                          (f) => f.medias.any((m) => m.id == selectedMedia.id),
                          orElse: () => formationsAll.first,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => YoutubePlayerPage(
                              video: selectedMedia,
                              videosInSameCategory: parentFormation.medias
                                  .map((m) => m)
                                  .toList(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Lire'),
                    ),
                    const SizedBox(height: 16),
                    Text('Autres médias', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ...mediasFiltres.map((m) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(m.titre, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(_formatDuration(Duration(seconds: m.duree ?? 0)), style: theme.textTheme.bodySmall),
                        onTap: () async {
                          final formationsAll = await _formationsFuture;
                          if (formationsAll == null || formationsAll.isEmpty) return;
                          final parentFormation = formationsAll.firstWhere(
                            (f) => f.medias.any((mm) => mm.id == m.id),
                            orElse: () => formationsAll.first,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => YoutubePlayerPage(
                                video: m,
                                videosInSameCategory: parentFormation.medias.map((mm) => mm).toList(),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  Flexible(flex: 2, child: Container(height: MediaQuery.of(context).size.height * 0.8, child: leftPanel())),
                  const SizedBox(width: 16),
                  Flexible(flex: 3, child: Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: rightPanel())),
                ],
              ),
            );
          },
        );
      },
    );

    return Stack(
      children: [
        _fromNotification
            ? CustomScaffold(
              body: body,
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
              appBar: AppBar(
                backgroundColor: AppColors.background,
                automaticallyImplyLeading: false,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      constraints: BoxConstraints(maxWidth: screenWidth * 0.5),
                      child: ToggleButtons(
                        isSelected: [
                          _selectedCategory == 'tutoriel',
                          _selectedCategory == 'astuce',
                        ],
                        onPressed: (index) {
                          setState(() {
                            _selectedCategory = index == 0 ? 'tutoriel' : 'astuce';
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
                    ),
                    const SizedBox(width: 12),
                    // Formation selector in the same app bar row
                    FutureBuilder<List<FormationWithMedias>>(
                      future: _formationsFuture,
                      builder: (context, snap) {
                        final items = snap.data ?? [];
                        if (items.isEmpty) return const SizedBox.shrink();
                        return Container(
                          constraints: BoxConstraints(maxWidth: screenWidth * 0.35),
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
                              });
                            },
                            underline: const SizedBox(),
                          ),
                        );
                      },
                    ),
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
              ),
              body: body,
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

  // Méthode _buildMediaItem améliorée pour le responsive
  Widget _buildMediaItem(
    BuildContext context,
    Media media,
    bool isWatched,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    final videoId = YoutubePlayer.convertUrlToId(media.url);
    final thumbnailUrl =
        videoId != null
            ? YoutubePlayer.getThumbnail(
              videoId: videoId,
              quality: ThumbnailQuality.medium,
            )
            : null;

    return FutureBuilder<Duration>(
      future: _getVideoDuration(media),
      builder: (context, snapshot) {
        final duration = snapshot.data ?? const Duration(seconds: 0);

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color:
              isWatched
                  ? colorScheme.surfaceVariant.withOpacity(0.7)
                  : const Color(0xFFFFF9C4),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              if (!isWatched) {
                final resp = await _mediaRepository
                    .markMediaAsWatchedWithResponse(media.id);
                final success = resp['success'] == true;
                if (success) setState(() => _loadWatchedMediaIds());
                final newAchievements =
                    (resp['newAchievements'] as List?) ?? [];
                if (newAchievements.isNotEmpty && mounted) {
                  _showNewBadgesDialog(context, newAchievements);
                }
              }

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
                      (_) => YoutubePlayerPage(
                        video: media,
                        videosInSameCategory:
                            selectedFormation.medias
                                .where((m) => m.categorie == media.categorie)
                                .toList(),
                      ),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
              child: Row(
                children: [
                  // Vignette de la vidéo
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width:
                            isSmallScreen
                                ? screenWidth * 0.3
                                : screenWidth * 0.35,
                        height:
                            isSmallScreen
                                ? screenWidth * 0.18
                                : screenWidth * 0.2,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          image:
                              thumbnailUrl != null
                                  ? DecorationImage(
                                    image: NetworkImage(thumbnailUrl),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                        ),
                        child:
                            thumbnailUrl == null
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
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
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  // Titre et informations
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          media.titre,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                isWatched
                                    ? colorScheme.onSurface.withOpacity(0.7)
                                    : colorScheme.onSurface,
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
}
