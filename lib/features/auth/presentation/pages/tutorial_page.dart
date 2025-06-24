import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/formation_with_medias.dart';
import 'package:wizi_learn/features/auth/data/repositories/media_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/auth_repository.dart';
import 'package:wizi_learn/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:wizi_learn/features/auth/presentation/constants/couleur_palette.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/youtube_player_page.dart';

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
  }

  Future<void> _loadFormations() async {
    try {
      final user = await _authRepository.getMe();
      debugPrint("Utilisateur récupéré : $user");

      final stagiaireId = user.stagiaire?.id;

      if (stagiaireId != null) {
        setState(() {
          _formationsFuture = _mediaRepository.getFormationsAvecMedias(stagiaireId);
        });
      } else {
        debugPrint("Aucun stagiaire lié");
        setState(() {
          _formationsFuture = Future.value([]); // Vide seulement si pas de stagiaire
        });
      }
    } catch (e) {
      debugPrint("Erreur : $e");
      setState(() {
        _formationsFuture = Future.error(e); // Ou Future.value([]) selon votre besoin
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text("Tutos et Astuces"),
        elevation: 1,
        centerTitle: true,
      ),

      body: FutureBuilder<List<FormationWithMedias>>(
        future: _formationsFuture,
        builder: (context, snapshot) {
          // État initial - pas encore chargé
          if (_formationsFuture == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // En cours de chargement
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Erreur
          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }

          // Données chargées
          final formations = snapshot.data ?? [];

          if (formations.isEmpty) {
            return const Center(child: Text("Aucune formation trouvée ny ino."));
          }

          final selectedFormation = formations.firstWhere(
                (f) => f.id == _selectedFormationId,
            orElse: () => formations.first,
          );

          final mediasFiltres = selectedFormation.medias
              .where((m) => m.categorie == _selectedCategory)
              .toList();

          return Column(
            children: [
              // Section Filtres combinés
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                    child: Row(
                      children: [
                        // Filtre Formation
                        Expanded(
                          flex: 2,
                          child: Container(
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                                icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary, size: 24),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Filtres Catégorie
                        Expanded(
                          flex: 1,
                          child: Container(
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
                              fillColor: Color(0xFFFEB823),
                              color: Color(0xFF181818),
                              constraints: const BoxConstraints(
                                minHeight: 40,
                                minWidth: 0,
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Liste des médias
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
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final media = mediasFiltres[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: const Color(0xFFFFF9C4), // Jaune clair
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => YoutubePlayerPage(
                                  video: media,
                                  videosInSameCategory: mediasFiltres,
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
                                    color: const Color(0xFFFFEB3B).withOpacity(0.8), // Jaune plus vif
                                    borderRadius: BorderRadius.circular(8),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        media.titre,
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        media.url,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.black54,
                                        ),
                                        maxLines: 1,
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
      ),
    );
  }
}