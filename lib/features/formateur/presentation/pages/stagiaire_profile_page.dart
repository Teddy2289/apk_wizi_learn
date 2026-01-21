import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/stagiaire_profile_model.dart';
import 'package:wizi_learn/features/formateur/data/repositories/stagiaire_profile_repository.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';

class StagiaireProfilePage extends StatefulWidget {
  final int stagiaireId;

  const StagiaireProfilePage({
    super.key,
    required this.stagiaireId,
  });

  @override
  State<StagiaireProfilePage> createState() => _StagiaireProfilePageState();
}

class _StagiaireProfilePageState extends State<StagiaireProfilePage>
    with SingleTickerProviderStateMixin {
  late final StagiaireProfileRepository _repository;
  late final TabController _tabController;

  StagiaireProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = StagiaireProfileRepository(
      apiClient: ApiClient(
        dio: Dio(),
        storage: const FlutterSecureStorage(),
      ),
    );
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await _repository.getProfileById(widget.stagiaireId);
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur de chargement: ${e.toString()}';
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_profile == null) return;

    final titleController = TextEditingController();
    final messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          'Message à ${_profile!.stagiaire.fullName}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: FormateurTheme.background,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: FormateurTheme.background,
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: FormateurTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  messageController.text.isNotEmpty) {
                final success = await _repository.sendMessage(
                  widget.stagiaireId,
                  titleController.text,
                  messageController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context, success);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FormateurTheme.accentDark,
              foregroundColor: Colors.white,
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message envoyé avec succès'),
          backgroundColor: FormateurTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormateurTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FormateurTheme.accent))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: FormateurTheme.error),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: FormateurTheme.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: FormateurTheme.accent,
                            foregroundColor: Colors.white),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _profile == null
                  ? const Center(child: Text('Aucune donnée', style: TextStyle(color: FormateurTheme.textSecondary)))
                  : NestedScrollView(
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return [
                          _buildSliverHeader(),
                          _buildSliverTabs(),
                        ];
                      },
                      body: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildProgressionTab(),
                          _buildEngagementTab(),
                          _buildCommunicationTab(),
                        ],
                      ),
                    ),
      floatingActionButton: _profile != null ? FloatingActionButton.extended(
        onPressed: _sendMessage,
        backgroundColor: FormateurTheme.accentDark,
        elevation: 4,
        icon: const Icon(Icons.send_rounded, color: Colors.white),
        label: const Text('MESSAGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }

  Widget _buildSliverHeader() {
    final stagiaire = _profile!.stagiaire;
    final stats = _profile!.stats;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: FormateurTheme.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            Container(color: FormateurTheme.background),
            // Profile Info Center
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: FormateurTheme.accent.withOpacity(0.3), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: FormateurTheme.accent.withOpacity(0.1),
                    backgroundImage: stagiaire.image != null ? NetworkImage(stagiaire.image!) : null,
                    child: stagiaire.image == null
                        ? Text(
                            stagiaire.prenom[0].toUpperCase(),
                            style: const TextStyle(fontSize: 40, color: FormateurTheme.accentDark, fontWeight: FontWeight.w900),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  stagiaire.fullName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: FormateurTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: FormateurTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: FormateurTheme.accent.withOpacity(0.2)),
                  ),
                  child: Text(
                    stats.currentBadge,
                    style: const TextStyle(color: FormateurTheme.accentDark, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                // Mini Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTopStat('POINTS', stats.totalPoints.toString(), Colors.blue),
                    _buildDivider(),
                    _buildTopStat('SCORE', '${stats.averageScore.toInt()}%', FormateurTheme.success),
                    _buildDivider(),
                    _buildTopStat('COMPLÉTÉS', stats.formationsCompleted.toString(), FormateurTheme.orangeAccent),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: FormateurTheme.textTertiary, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 24,
      width: 1,
      color: FormateurTheme.border,
    );
  }

  Widget _buildSliverTabs() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: FormateurTheme.accentDark,
          labelColor: FormateurTheme.accentDark,
          unselectedLabelColor: FormateurTheme.textTertiary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.2),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'PARCOURS'),
            Tab(text: 'ACTIVITÉ'),
            Tab(text: 'INFO'),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressionTab() {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: FormateurTheme.accent,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'FORMATIONS EN COURS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          if (_profile!.formations.isEmpty)
             Container(
               padding: const EdgeInsets.all(32),
               alignment: Alignment.center,
               child: const Text('Aucune formation active', style: TextStyle(color: FormateurTheme.textTertiary)),
             )
          else
            ..._profile!.formations.map((formation) => _buildFormationCard(formation)),

          const SizedBox(height: 32),

          const Text(
            'HISTORIQUE DES QUIZ',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          if (_profile!.quizHistory.isEmpty)
            Container(
               padding: const EdgeInsets.all(32),
               alignment: Alignment.center,
               child: const Text('Aucun quiz complété', style: TextStyle(color: FormateurTheme.textTertiary)),
             )
          else
            ..._profile!.quizHistory.map((quiz) => _buildQuizCard(quiz)),
        ],
      ),
    );
  }

  Widget _buildFormationCard(dynamic formation) {
    final color = formation.isCompleted ? FormateurTheme.success : FormateurTheme.accentDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FormateurTheme.border),
        boxShadow: FormateurTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(formation.isCompleted ? Icons.check_circle : Icons.play_circle_fill, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  formation.title.toUpperCase(),
                  style: const TextStyle(color: FormateurTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${formation.progress}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: formation.progress / 100,
              minHeight: 8,
              backgroundColor: FormateurTheme.background,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(dynamic quiz) {
    final color = quiz.percentage >= 70 ? FormateurTheme.success : quiz.percentage >= 50 ? FormateurTheme.orangeAccent : FormateurTheme.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FormateurTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${quiz.percentage.toInt()}%',
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: const TextStyle(color: FormateurTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  quiz.category,
                  style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${quiz.score}/${quiz.maxScore}',
                style: const TextStyle(color: FormateurTheme.textPrimary, fontWeight: FontWeight.w900),
              ),
              Text(
                _formatDate(quiz.completedAt),
                style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'ACTIVITÉS RÉCENTES',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 16),
        if (_profile!.activity.recentActivities.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('Aucune activité récente', style: TextStyle(color: FormateurTheme.textTertiary)),
          ))
        else
          ..._profile!.activity.recentActivities.map((activity) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FormateurTheme.border),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: FormateurTheme.accent.withOpacity(0.1),
                      shape: BoxShape.circle
                    ),
                    child: Icon(_getActivityIcon(activity.type), color: FormateurTheme.accentDark, size: 20),
                  ),
                  title: Text(activity.title, style: const TextStyle(color: FormateurTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(_formatDate(activity.timestamp), style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 11)),
                  trailing: activity.score != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: FormateurTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text('${activity.score}%', style: const TextStyle(color: FormateurTheme.success, fontWeight: FontWeight.bold, fontSize: 12)),
                        )
                      : null,
                ),
              )),
      ],
    );
  }

  Widget _buildCommunicationTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'COORDONNÉES',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 16),
        _buildInfoTile(Icons.email_outlined, 'EMAIL', _profile!.stagiaire.email),
        _buildInfoTile(Icons.phone_outlined, 'TELEPHONE', 'Non renseigné'),
        const SizedBox(height: 32),
        const Text(
          'NOTES PRIVÉES',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FormateurTheme.border),

          ),
          child: Column(
            children: [
              const Icon(Icons.edit_note_rounded, color: FormateurTheme.textTertiary, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Ajouter des notes sur cet apprenant pour votre suivi personnel.',
                textAlign: TextAlign.center,
                style: TextStyle(color: FormateurTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FormateurTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: FormateurTheme.textTertiary, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: FormateurTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  bool _isRecentlyActive() {
    if (_profile?.stagiaire.lastLogin == null) return false;
    try {
      final lastLogin = DateTime.parse(_profile!.stagiaire.lastLogin!);
      final diff = DateTime.now().difference(lastLogin);
      return diff.inHours < 24;
    } catch (e) {
      return false;
    }
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inDays == 0) {
        return 'Aujourd\'hui';
      } else if (diff.inDays == 1) {
        return 'Hier';
      } else if (diff.inDays < 7) {
        return 'Il y a ${diff.inDays}j';
      } else {
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (e) {
      return date;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'quiz_completed':
        return Icons.quiz_outlined;
      case 'formation_started':
        return Icons.play_lesson_outlined;
      case 'formation_completed':
        return Icons.check_circle_outline;
      default:
        return Icons.calendar_today_outlined;
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
