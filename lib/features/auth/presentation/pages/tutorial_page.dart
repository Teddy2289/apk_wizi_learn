import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/formation_with_medias.dart';
import 'package:wizi_learn/features/auth/data/repositories/media_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/auth_repository.dart';
import 'package:wizi_learn/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:wizi_learn/features/auth/data/models/media_model.dart';
import 'package:wizi_learn/features/auth/presentation/constants/couleur_palette.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/youtube_player_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/custom_scaffold.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
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
    } catch (e) {
      debugPrint("Erreur : $e");
      setState(() {
        _formationsFuture = Future.error(e);
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    final body = FutureBuilder<List<FormationWithMedias>>(
      future: _formationsFuture,
      builder: (context, snapshot) {
        if (_formationsFuture == null ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Erreur : ${snapshot.error}"));
        }

        final formations = snapshot.data ?? [];

        if (formations.isEmpty) {
          return const Center(child: Text("Aucune formation trouvée."));
        }

        final selectedFormation = formations.firstWhere(
          (f) => f.id == _selectedFormationId,
          orElse: () => formations.first,
        );

        final mediasFiltres =
            selectedFormation.medias
                .where((m) => m.categorie == _selectedCategory)
                .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;

                  // Hide the formation dropdown if there is only one formation
                  if (formations.length <= 1) {
                    return const SizedBox.shrink();
                  }

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _selectedFormationId ?? selectedFormation.id,
                          items:
                              formations.map((formation) {
                                return DropdownMenuItem<int>(
                                  value: formation.id,
                                  child: Text(
                                    formation.titre.toUpperCase(),
                                    style: theme.textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedFormationId = value;
                            });
                          },
                          underline: const SizedBox(),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: colorScheme.primary,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Liste des médias
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child:
                    mediasFiltres.isEmpty
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
                              ),
                            ],
                          ),
                        )
                        : ListView.separated(
                          itemCount: mediasFiltres.length,
                          separatorBuilder:
                              (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final media = mediasFiltres[index];
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: const Color(0xFFFFF9C4),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => YoutubePlayerPage(
                                            video: Media(
                                              id: media.id,
                                              titre: media.titre,
                                              description: media.description,
                                              url: normalizeYoutubeUrl(
                                                media.url,
                                              ),
                                              type: media.type,
                                              categorie: media.categorie,
                                              duree: media.duree,
                                              formationId: media.formationId,
                                            ),
                                            videosInSameCategory:
                                                mediasFiltres
                                                    .map(
                                                      (m) => Media(
                                                        id: m.id,
                                                        titre: m.titre,
                                                        description:
                                                            m.description,
                                                        url:
                                                            normalizeYoutubeUrl(
                                                              m.url,
                                                            ),
                                                        type: m.type,
                                                        categorie: m.categorie,
                                                        duree: m.duree,
                                                        formationId:
                                                            m.formationId,
                                                      ),
                                                    )
                                                    .toList(),
                                          ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFFFEB3B,
                                          ).withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.play_circle_filled,
                                          size: 32,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              media.titre,
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ),
          ],
        );
      },
    );

    return Stack(
      children: [
        _fromNotification
            ? CustomScaffold(
              body: body,
              currentIndex: 4, // Index de l'onglet Tutoriel
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
                title: ToggleButtons(
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
                    minWidth: screenWidth / 2 - 32,
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('Tutos'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Astuces'),
                    ),
                  ],
                ),
                elevation: 1,
                centerTitle: true,
              ),
              body: body,
            ),
        if (_showTutorial) _buildTutorialOverlay(context),
      ],
    );
  }
}
