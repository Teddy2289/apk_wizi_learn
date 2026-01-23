import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/analytics_model.dart';
import 'package:wizi_learn/features/formateur/data/repositories/analytics_repository.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';

class FormateurVideosPage extends StatefulWidget {
  const FormateurVideosPage({super.key});

  @override
  State<FormateurVideosPage> createState() => _FormateurVideosPageState();
}

class _FormateurVideosPageState extends State<FormateurVideosPage> {
  late final AnalyticsRepository _repository;
  bool _loading = true;
  List<FormationVideos> _formations = [];

  @override
  void initState() {
    super.initState();
    _repository = AnalyticsRepository(
      apiClient: ApiClient(
        dio: Dio(),
        storage: const FlutterSecureStorage(),
      ),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final formations = await _repository.getFormationsVideos();
      setState(() {
        _formations = formations;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: FormateurTheme.error),
        );
      }
    }
  }

  void _showVideoStats(int videoId, String titre) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VideoStatsSheet(
        videoId: videoId,
        titre: titre,
        repository: _repository,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormateurTheme.background,
      appBar: AppBar(
        title: const Text('Vidéos & Tracking'),
        backgroundColor: Colors.white,
        foregroundColor: FormateurTheme.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: FormateurTheme.textPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 20,
          fontFamily: 'Montserrat',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FormateurTheme.accent))
          : _formations.isEmpty
              ? const Center(child: Text('Aucune formation avec vidéos trouvée'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: FormateurTheme.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _formations.length,
                    itemBuilder: (context, index) {
                      final formation = _formations[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: FormateurTheme.border),
                          boxShadow: FormateurTheme.cardShadow,
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: FormateurTheme.accent.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.video_library_rounded, color: FormateurTheme.accent, size: 20),
                            ),
                            title: Text(
                              formation.titre,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: FormateurTheme.textPrimary),
                            ),
                            subtitle: Text(
                              '${formation.videos.length} leçons vidéo',
                              style: const TextStyle(fontSize: 12, color: FormateurTheme.textTertiary, fontWeight: FontWeight.bold),
                            ),
                            children: formation.videos.map((video) {
                              return Container(
                                decoration: const BoxDecoration(
                                  border: Border(top: BorderSide(color: FormateurTheme.border)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                  title: Text(
                                    video.titre,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FormateurTheme.textSecondary),
                                  ),
                                  trailing: const Icon(Icons.analytics_outlined, color: FormateurTheme.accent, size: 18),
                                  onTap: () => _showVideoStats(video.id, video.titre),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _VideoStatsSheet extends StatefulWidget {
  final int videoId;
  final String titre;
  final AnalyticsRepository repository;

  const _VideoStatsSheet({
    required this.videoId,
    required this.titre,
    required this.repository,
  });

  @override
  State<_VideoStatsSheet> createState() => _VideoStatsSheetState();
}

class _VideoStatsSheetState extends State<_VideoStatsSheet> {
  bool _loading = true;
  VideoStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await widget.repository.getVideoStats(widget.videoId);
    if (mounted) {
      setState(() {
        _stats = stats;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.titre,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: FormateurTheme.textPrimary, fontFamily: 'Montserrat'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: FormateurTheme.background, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, size: 20, color: FormateurTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: FormateurTheme.accent)))
          else if (_stats == null)
            const Center(child: Text('Erreur lors du chargement des statistiques'))
          else ...[
            // Stats Row
            Row(
              children: [
                _buildMiniStat('Vues', _stats!.totalViews.toString(), Icons.remove_red_eye_outlined, Colors.blue),
                const SizedBox(width: 16),
                _buildMiniStat('Complétion', '${_stats!.completionRate}%', Icons.check_circle_outline, FormateurTheme.success),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'VUES PAR STAGIAIRE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),
            if (_stats!.viewsByStagiaire.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Aucune vue enregistrée', style: TextStyle(color: FormateurTheme.textTertiary))))
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _stats!.viewsByStagiaire.length,
                  itemBuilder: (context, index) {
                    final view = _stats!.viewsByStagiaire[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FormateurTheme.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: FormateurTheme.accent.withOpacity(0.1),
                            child: const Icon(Icons.person, size: 16, color: FormateurTheme.accent),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${view.prenom} ${view.nom}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FormateurTheme.textPrimary)),
                                Text('${view.percentage}% complété', style: const TextStyle(fontSize: 11, color: FormateurTheme.textSecondary)),
                              ],
                            ),
                          ),
                          if (view.completed)
                            const Icon(Icons.verified_rounded, color: FormateurTheme.success, size: 18)
                          else
                            Text('${view.percentage}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: FormateurTheme.accent)),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
            Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color.withOpacity(0.7), letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}
