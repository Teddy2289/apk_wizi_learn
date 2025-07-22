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

  @override
  void initState() {
    super.initState();
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
      }
    });
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
  Widget _buildMediaItem(
      BuildContext context,
      Media media,
      bool isWatched,
      ThemeData theme,
      ColorScheme colorScheme,
      ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final videoId = YoutubePlayer.convertUrlToId(media.url);
    final thumbnailUrl = videoId != null
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
          color: isWatched
              ? colorScheme.surfaceVariant.withOpacity(0.7)
              : const Color(0xFFFFF9C4),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              if (!isWatched) {
                final success = await _mediaRepository.markMediaAsWatched(media.id);
                if (success) setState(() => _loadWatchedMediaIds());
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
                  builder: (_) => YoutubePlayerPage(
                    video: media,
                    videosInSameCategory: selectedFormation.medias
                        .where((m) => m.categorie == media.categorie)
                        .toList(),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Vignette de la vidéo
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: screenWidth * 0.35,
                        height: screenWidth * 0.2,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          image: thumbnailUrl != null
                              ? DecorationImage(
                            image: NetworkImage(thumbnailUrl),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: thumbnailUrl == null
                            ? const Icon(Icons.videocam, size: 32)
                            : null,
                      ),
                      const Icon(
                        Icons.play_circle_fill,
                        size: 36,
                        color: Colors.white,
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
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatDuration(duration),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Titre et informations
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          media.titre,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isWatched
                                ? colorScheme.onSurface.withOpacity(0.7)
                                : colorScheme.onSurface,
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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

        final mediasFiltres = selectedFormation.medias
            .where((m) => m.categorie == _selectedCategory)
            .toList();

        return FutureBuilder<Set<int>>(
          future: _watchedMediaIdsFuture,
          builder: (context, watchedSnapshot) {
            final watchedMediaIds = watchedSnapshot.data ?? {};

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
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
                              items: formations.map((formation) {
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                          ),
                        ],
                      ),
                    )
                        : ListView.separated(
                      itemCount: mediasFiltres.length,
                      separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final media = mediasFiltres[index];
                        final isWatched = watchedMediaIds.contains(media.id);
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
          },
        );
      },
    );

    // Si on vient d'une notification, utiliser CustomScaffold
    if (_fromNotification) {
      return CustomScaffold(
        body: body,
        currentIndex: 4, // Index de l'onglet Tutoriel
        onTabSelected: (index) {
          // Navigation vers les autres onglets
          Navigator.pushReplacementNamed(
            context,
            RouteConstants.dashboard,
            arguments: index,
          );
        },
        showBanner: true,
      );
    }

    // Sinon, utiliser le Scaffold normal
    return Scaffold(
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
    );
  }
}