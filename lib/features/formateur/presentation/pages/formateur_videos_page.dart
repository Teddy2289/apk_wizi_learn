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
        title: const Text('Vidéos'),
        backgroundColor: Colors.white,
        foregroundColor: FormateurTheme.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: FormateurTheme.textPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          fontFamily: 'Montserrat',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: FormateurTheme.border, height: 1),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FormateurTheme.accent))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: FormateurTheme.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildPremiumHeader(),
                    if (_formations.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(child: Text('Aucune formation avec vidéos trouvée')),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        itemCount: _formations.length,
                        itemBuilder: (context, index) {
                          final formation = _formations[index];
                          return _buildFormationVideoGroup(formation);
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: FormateurTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.video_collection_rounded, size: 12, color: FormateurTheme.accentDark),
                const SizedBox(width: 8),
                Text(
                  'Médiathèque',
                  style: TextStyle(
                    color: FormateurTheme.accentDark,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Atelier Vidéo',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: FormateurTheme.textPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Analysez l'engagement de vos stagiaires sur vos contenus pédagogiques.",
            style: TextStyle(
              color: FormateurTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormationVideoGroup(FormationVideos formation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: FormateurTheme.premiumCardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FormateurTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.school_rounded, color: FormateurTheme.accentDark, size: 20),
          ),
          title: Text(
            formation.titre,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: FormateurTheme.textPrimary, letterSpacing: -0.2),
          ),
          subtitle: Text(
            '${formation.videos.length} Unités vidéo',
            style: const TextStyle(fontSize: 10, color: FormateurTheme.textTertiary, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          trailing: const Icon(Icons.expand_more_rounded, color: FormateurTheme.border),
          children: formation.videos.map((video) {
            return Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: FormateurTheme.border)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                hoverColor: FormateurTheme.accent.withOpacity(0.05),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FormateurTheme.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_circle_fill_rounded, color: FormateurTheme.textSecondary, size: 20),
                ),
                title: Text(
                  video.titre,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FormateurTheme.textSecondary),
                ),
                trailing: const Icon(Icons.analytics_rounded, color: FormateurTheme.border, size: 20),
                onTap: () {
                   HapticFeedback.lightImpact();
                   _showVideoStats(video.id, video.titre);
                },
              ),
            );
          }).toList(),
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
    try {
      final stats = await widget.repository.getVideoStats(widget.videoId);
      if (mounted) {
        setState(() {
          _stats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: FormateurTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: FormateurTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.analytics_rounded, color: FormateurTheme.accentDark, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Statistiques vidéo', style: TextStyle(color: FormateurTheme.textTertiary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    Text(
                      widget.titre,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: FormateurTheme.textPrimary, letterSpacing: -0.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: FormateurTheme.accent)))
          else if (_stats == null)
            const Center(child: Text('Données indisponibles'))
          else ...[
            Row(
              children: [
                _buildMetricCard('Vues Totales', _stats!.totalViews.toString(), Icons.visibility_rounded, Colors.blue),
                const SizedBox(width: 16),
                _buildMetricCard('Taux de Complétion', '${_stats!.completionRate}%', Icons.verified_user_rounded, FormateurTheme.success),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Audience par stagiaire',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),
            if (_stats!.viewsByStagiaire.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Aucune donnée de visionnage', style: TextStyle(color: FormateurTheme.textTertiary))))
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _stats!.viewsByStagiaire.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final view = _stats!.viewsByStagiaire[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FormateurTheme.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: FormateurTheme.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white,
                            child: Text(view.prenom[0].toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: FormateurTheme.accentDark)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${view.prenom} ${view.nom}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: FormateurTheme.textPrimary)),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: view.percentage / 100,
                                          backgroundColor: Colors.white,
                                          valueColor: AlwaysStoppedAnimation<Color>(view.completed ? FormateurTheme.success : FormateurTheme.accent),
                                          minHeight: 4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${view.percentage}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: view.completed ? FormateurTheme.success : FormateurTheme.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
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

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: FormateurTheme.border),
          boxShadow: FormateurTheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: FormateurTheme.textPrimary, letterSpacing: -1)),
            Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}
