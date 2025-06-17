import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';

// Modèle Formation
class Formation {
  final String id;
  final String titre;
  Formation({required this.id, required this.titre});
  factory Formation.fromJson(Map<String, dynamic> json) => Formation(
        id: json['id'].toString(),
        titre: json['titre'] ?? '',
      );
}

// Modèle Media
class Media {
  final String id;
  final String titre;
  final String type; // video, audio, document, image
  final String categorie;
  final int duree;
  final String url;
  final String category; // 'tutoriel' ou 'astuce'
  Media({
    required this.id,
    required this.titre,
    required this.type,
    required this.categorie,
    required this.duree,
    required this.url,
    required this.category,
  });
  factory Media.fromJson(Map<String, dynamic> json) => Media(
        id: json['id'].toString(),
        titre: json['titre'] ?? '',
        type: json['type'] ?? '',
        categorie: json['categorie'] ?? '',
        duree: json['duree'] is int ? json['duree'] : int.tryParse(json['duree'].toString()) ?? 0,
        url: json['url'] ?? '',
        category: json['category'] ?? '',
      );
}

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});
  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  static const String baseUrl = "https://wizi-learn.com/api";
  List<Formation> formations = [];
  String? selectedFormationId;
  String activeCategory = 'tutoriel';
  List<Media> medias = [];
  Map<String, Map<String, List<Media>>> groupedMediasByType = {};
  Media? selectedMedia;
  bool isLoading = true;
  bool isFetching = false;
  Map<String, bool> expandedSections = {};

  // Pour le player
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    fetchFormations();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> fetchFormations() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/formations'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        formations = (data as List).map((e) => Formation.fromJson(e)).toList();
        selectedFormationId = formations.isNotEmpty ? formations[0].id : null;
        await fetchMedias();
      }
    } catch (e) {
      print('Erreur formations: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> fetchMedias() async {
    setState(() => isFetching = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/medias?formation_id=$selectedFormationId'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final tutoriels = (data['tutoriels'] as List?)?.map((e) => Media.fromJson(e)).toList() ?? [];
        final astuces = (data['astuces'] as List?)?.map((e) => Media.fromJson(e)).toList() ?? [];
        medias = activeCategory == 'tutoriel' ? tutoriels : astuces;
        filterAndGroupMedias();
      }
    } catch (e) {
      print('Erreur medias: $e');
    }
    setState(() => isFetching = false);
  }

  void filterAndGroupMedias() {
    groupedMediasByType = {};
    for (var media in medias) {
      final type = media.type;
      final cat = media.categorie;
      groupedMediasByType[type] ??= {};
      groupedMediasByType[type]![cat] ??= [];
      groupedMediasByType[type]![cat]!.add(media);
    }
    if (medias.isNotEmpty) {
      selectedMedia = medias.firstWhere(
        (m) => selectedMedia != null && m.id == selectedMedia!.id,
        orElse: () => medias[0],
      );
      _initPlayer(selectedMedia!);
    } else {
      selectedMedia = null;
      _disposePlayers();
    }
    expandedSections = {
      for (var type in groupedMediasByType.keys) type: true,
    };
  }

  void _disposePlayers() {
    _videoController?.dispose();
    _videoController = null;
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _isPlayerReady = false;
  }

  Future<void> _initPlayer(Media media) async {
    _disposePlayers();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutoriels & Astuces')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Sélecteur de formation
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton<String>(
                    value: selectedFormationId,
                    items: formations
                        .map<DropdownMenuItem<String>>(
                          (f) => DropdownMenuItem(
                            value: f.id,
                            child: Text(f.titre),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() => selectedFormationId = v);
                      fetchMedias();
                    },
                  ),
                ),
                // Onglets tutoriel/astuce
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Tutoriels'),
                      selected: activeCategory == 'tutoriel',
                      onSelected: (v) {
                        setState(() => activeCategory = 'tutoriel');
                        fetchMedias();
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Astuces'),
                      selected: activeCategory == 'astuce',
                      onSelected: (v) {
                        setState(() => activeCategory = 'astuce');
                        fetchMedias();
                      },
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: isFetching ? null : fetchMedias,
                      child: isFetching ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Rafraîchir'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: isFetching
                      ? const Center(child: CircularProgressIndicator())
                      : groupedMediasByType.isEmpty
                          ? const Center(child: Text('Aucun média disponible'))
                          : Row(
                              children: [
                                // Playlist (gauche)
                                Expanded(
                                  flex: 2,
                                  child: ListView(
                                    children: groupedMediasByType.entries.map((typeEntry) {
                                      final type = typeEntry.key;
                                      final categories = typeEntry.value;
                                      return ExpansionTile(
                                        title: Text(type.toUpperCase()),
                                        initiallyExpanded: expandedSections[type] ?? true,
                                        onExpansionChanged: (v) => setState(() => expandedSections[type] = v),
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
                                                    selected: selectedMedia != null && selectedMedia!.id == media.id,
                                                    onTap: () async {
                                                      setState(() => selectedMedia = media);
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
                                  child: selectedMedia == null
                                      ? const Center(child: Text('Sélectionnez un média'))
                                      : Center(
                                          child: Card(
                                            margin: const EdgeInsets.all(24),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(selectedMedia!.titre, style: Theme.of(context).textTheme.titleLarge),
                                                  const SizedBox(height: 16),
                                                  if (selectedMedia!.type == 'video' && _videoController != null && _isPlayerReady)
                                                    AspectRatio(
                                                      aspectRatio: _videoController!.value.aspectRatio,
                                                      child: VideoPlayer(_videoController!),
                                                    )
                                                  else if (selectedMedia!.type == 'audio' && _audioPlayer != null && _isPlayerReady)
                                                    AudioPlayerWidget(player: _audioPlayer!)
                                                  else if (selectedMedia!.type == 'image')
                                                    Image.network(selectedMedia!.url, height: 200, fit: BoxFit.contain)
                                                  else if (selectedMedia!.type == 'document')
                                                    const Icon(Icons.insert_drive_file, size: 80)
                                                  else
                                                    const Placeholder(fallbackHeight: 200),
                                                  const SizedBox(height: 8),
                                                  Text('Durée: ${selectedMedia!.duree} min'),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                ),
              ],
            ),
    );
  }
}

// Widget audio simple
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
