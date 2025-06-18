import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/formation_model.dart';
import 'package:wizi_learn/features/auth/data/models/user_model.dart';
import 'package:wizi_learn/features/auth/data/models/media_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/formation_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/media_repository.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wizi_learn/features/auth/domain/user_entity.dart';

class TutorialPage extends StatefulWidget {
  final UserEntity user;
  const TutorialPage({super.key, required this.user});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  late final FormationRepository _formationRepository;
  late final MediaRepository _mediaRepository;
  late Future<List<Formation>> _futureFormations;
  String? _selectedFormationId;
  String _activeCategory = 'tutoriel';
  Future<List<Media>>? _futureMedias;
  List<Media> _medias = [];
  Map<String, Map<String, List<Media>>> _groupedMediasByType = {};
  Media? _selectedMedia;
  Map<String, bool> _expandedSections = {};
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _formationRepository = FormationRepository(apiClient: apiClient);
    _mediaRepository = MediaRepository(apiClient: apiClient);
    _futureFormations = _formationRepository.getFormationsByStagiaire(widget.user.stagiaire?.id);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _onFormationChanged(String? formationId) {
    setState(() {
      _selectedFormationId = formationId;
      _futureMedias = _mediaRepository.getMediasByFormation(
        formationId,
        category: _activeCategory,
      );
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _activeCategory = category;
      if (_selectedFormationId != null) {
        _futureMedias = _mediaRepository.getMediasByFormation(
          _selectedFormationId,
          category: _activeCategory,
        );
      }
    });
  }

  Future<void> _initPlayer(Media media) async {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    _videoController = null;
    _audioPlayer = null;
    _isPlayerReady = false;
    if (media.type == 'video') {
      _videoController = VideoPlayerController.network(media.url);
      await _videoController!.initialize();
      setState(() => _isPlayerReady = true);
    } else if (media.type == 'audio') {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setUrl(media.url);
      setState(() => _isPlayerReady = true);
    } else {
      setState(() => _isPlayerReady = false);
    }
  }

  void _groupMedias(List<Media> medias) {
    _groupedMediasByType = {};
    for (var media in medias) {
      final type = media.type;
      final cat = media.categorie;
      _groupedMediasByType[type] ??= {};
      _groupedMediasByType[type]![cat] ??= [];
      _groupedMediasByType[type]![cat]!.add(media);
    }
    if (medias.isNotEmpty) {
      _selectedMedia = medias.first;
      _initPlayer(_selectedMedia!);
    } else {
      _selectedMedia = null;
      _videoController?.dispose();
      _audioPlayer?.dispose();
      _isPlayerReady = false;
    }
    _expandedSections = {
      for (var type in _groupedMediasByType.keys) type: true,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutoriels & Astuces')),
      body: FutureBuilder<List<Formation>>(
        future: _futureFormations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune formation disponible'));
          }
          final formations = snapshot.data!;
          _selectedFormationId ??= formations.first.id.toString();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<String>(
                  value: _selectedFormationId,
                  items: formations
                      .map<DropdownMenuItem<String>>(
                        (f) => DropdownMenuItem(
                          value: f.id.toString(),
                          child: Text(f.titre),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => _onFormationChanged(v),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Tutoriels'),
                    selected: _activeCategory == 'tutoriel',
                    onSelected: (v) => _onCategoryChanged('tutoriel'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Astuces'),
                    selected: _activeCategory == 'astuce',
                    onSelected: (v) => _onCategoryChanged('astuce'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _selectedFormationId == null
                    ? const Center(child: Text('Sélectionnez une formation'))
                    : FutureBuilder<List<Media>>(
                        future: _mediaRepository.getMediasByFormation(
                          _selectedFormationId,
                          category: _activeCategory,
                        ),
                        builder: (context, mediaSnapshot) {
                          if (mediaSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (mediaSnapshot.hasError) {
                            return Center(child: Text('Erreur: ${mediaSnapshot.error}'));
                          } else if (!mediaSnapshot.hasData || mediaSnapshot.data!.isEmpty) {
                            return const Center(child: Text('Aucun média disponible'));
                          }
                          _medias = mediaSnapshot.data!;
                          _groupMedias(_medias);
                          return Row(
                            children: [
                              // Playlist (gauche)
                              Expanded(
                                flex: 2,
                                child: ListView(
                                  children: _groupedMediasByType.entries.map((typeEntry) {
                                    final type = typeEntry.key;
                                    final categories = typeEntry.value;
                                    return ExpansionTile(
                                      title: Text(type.toUpperCase()),
                                      initiallyExpanded: _expandedSections[type] ?? true,
                                      onExpansionChanged: (v) => setState(() => _expandedSections[type] = v),
                                      children: categories.entries.map((catEntry) {
                                        final cat = catEntry.key;
                                        final items = catEntry.value;
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                              child: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            ...items.map<Widget>((media) => ListTile(
                                                  title: Text(media.titre),
                                                  subtitle: Text('${media.duree} min'),
                                                  selected: _selectedMedia != null && _selectedMedia!.id == media.id,
                                                  onTap: () async {
                                                    setState(() => _selectedMedia = media);
                                                    await _initPlayer(media);
                                                  },
                                                )),
                                          ],
                                        );
                                      }).toList(),
                                    );
                                  }).toList(),
                                ),
                              ),
                              // Player (droite)
                              Expanded(
                                flex: 3,
                                child: _selectedMedia == null
                                    ? const Center(child: Text('Sélectionnez un média'))
                                    : Center(
                                        child: Card(
                                          margin: const EdgeInsets.all(24),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(_selectedMedia!.titre, style: Theme.of(context).textTheme.titleLarge),
                                                const SizedBox(height: 16),
                                                if (_selectedMedia!.type == 'video' && _videoController != null && _isPlayerReady)
                                                  AspectRatio(
                                                    aspectRatio: _videoController!.value.aspectRatio,
                                                    child: VideoPlayer(_videoController!),
                                                  )
                                                else if (_selectedMedia!.type == 'audio' && _audioPlayer != null && _isPlayerReady)
                                                  AudioPlayerWidget(player: _audioPlayer!)
                                                else if (_selectedMedia!.type == 'image')
                                                  Image.network(_selectedMedia!.url, height: 200, fit: BoxFit.contain)
                                                else if (_selectedMedia!.type == 'document')
                                                  const Icon(Icons.insert_drive_file, size: 80)
                                                else
                                                  const Placeholder(fallbackHeight: 200),
                                                const SizedBox(height: 8),
                                                Text('Durée: ${_selectedMedia!.duree} min'),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final AudioPlayer player;
  const AudioPlayerWidget({super.key, required this.player});
  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool isPlaying = false;
  @override
  void initState() {
    super.initState();
    widget.player.playerStateStream.listen((state) {
      setState(() => isPlaying = state.playing);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () {
            if (isPlaying) {
              widget.player.pause();
            } else {
              widget.player.play();
            }
          },
        ),
        const Text('Audio'),
      ],
    );
  }
}
