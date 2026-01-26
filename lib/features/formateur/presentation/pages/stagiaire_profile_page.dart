import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/stagiaire_profile_model.dart';
import 'package:wizi_learn/features/formateur/data/repositories/stagiaire_profile_repository.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';

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
                      Text(_error!, style: const TextStyle(color: FormateurTheme.textSecondary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: FormateurTheme.accentDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('RÉESSAYER'),
                      ),
                    ],
                  ),
                )
              : _profile == null
                  ? const Center(child: Text('Aucune donnée', style: TextStyle(color: FormateurTheme.textSecondary)))
                  : NestedScrollView(
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return [
                          _buildPremiumProfileHeader(),
                          _buildSliverTabs(),
                        ];
                      },
                      body: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildParcoursTab(),
                          _buildActivityTab(),
                          _buildInformationTab(),
                        ],
                      ),
                    ),
      floatingActionButton: _profile != null ? FloatingActionButton.extended(
        onPressed: _sendMessage,
        backgroundColor: FormateurTheme.textPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.chat_bubble_rounded, color: FormateurTheme.accent, size: 20),
        label: const Text('CONTACTER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ) : null,
    );
  }

  Widget _buildPremiumProfileHeader() {
    final s = _profile!.stagiaire;
    final stats = _profile!.stats;

    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: FormateurTheme.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Column(
          children: [
             Container(
              height: 140,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: FormateurTheme.yellowWhiteGradient,
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -50),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: FormateurTheme.background,
                      backgroundImage: s.image != null && s.image!.isNotEmpty 
                          ? NetworkImage(AppConstants.getUserImageUrl(s.image!)) : null,
                      child: s.image == null ? Text(s.prenom[0].toUpperCase(), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900)) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.fullName.toUpperCase(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: FormateurTheme.textPrimary, letterSpacing: -1),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: FormateurTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(30)),
                    child: Text(stats.currentBadge.toUpperCase(), style: const TextStyle(color: FormateurTheme.accentDark, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHeaderMetric('POINTS', stats.totalPoints.toString(), Colors.blue),
                        _buildHeaderMetric('SCORE', '${stats.averageScore.toInt()}%', FormateurTheme.success),
                        _buildHeaderMetric('SÉRIE', '${stats.loginStreak}j', FormateurTheme.orangeAccent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 1.0)),
      ],
    );
  }

  Widget _buildSliverTabs() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: FormateurTheme.accentDark,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: FormateurTheme.textPrimary,
          unselectedLabelColor: FormateurTheme.textTertiary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0),
          tabs: const [
            Tab(text: 'PARCOURS'),
            Tab(text: 'ACTIVITÉ'),
            Tab(text: 'PROFILE'),
          ],
        ),
      ),
    );
  }

  Widget _buildParcoursTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('FORMATIONS EN COURS', style: TextStyle(color: FormateurTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        if (_profile!.formations.isEmpty)
           _buildEmptyTabState(Icons.school_outlined, 'Aucune formation active')
        else
          ..._profile!.formations.map((f) => _buildFormationProgressCard(f)),
        
        const SizedBox(height: 32),
        const Text('EXCELLENCE QUIZ', style: TextStyle(color: FormateurTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        if (_profile!.quizHistory.isEmpty)
          _buildEmptyTabState(Icons.quiz_outlined, 'Aucun quiz effectué')
        else
          ..._profile!.quizHistory.map((q) => _buildQuizHistoryItem(q)),
      ],
    );
  }

  Widget _buildFormationProgressCard(FormationProgress f) {
    final color = f.isCompleted ? FormateurTheme.success : FormateurTheme.accentDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: FormateurTheme.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(f.title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: FormateurTheme.textPrimary, letterSpacing: -0.2))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${f.progress}%', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: f.progress / 100,
              minHeight: 6,
              backgroundColor: FormateurTheme.background,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizHistoryItem(QuizResult q) {
    final color = q.percentage >= 70 ? FormateurTheme.success : q.percentage >= 50 ? FormateurTheme.orangeAccent : FormateurTheme.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: FormateurTheme.premiumCardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Text('${q.percentage.toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: FormateurTheme.textPrimary)),
                Text(_formatDate(q.completedAt).toUpperCase(), style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 9, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Text('${q.score}/${q.maxScore}', style: const TextStyle(fontWeight: FontWeight.w900, color: FormateurTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('ENGAGEMENT RÉCENT', style: TextStyle(color: FormateurTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 20),
        if (_profile!.activity.recentActivities.isEmpty)
          _buildEmptyTabState(Icons.timeline_rounded, 'Aucun historique récent')
        else
          ..._profile!.activity.recentActivities.map((a) => _buildActivityItem(a)),
      ],
    );
  }

  Widget _buildActivityItem(RecentActivity a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: FormateurTheme.premiumCardDecoration,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: FormateurTheme.accent.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Icon(_getActivityIcon(a.type), color: FormateurTheme.accentDark, size: 20),
        ),
        title: Text(a.title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: FormateurTheme.textPrimary, letterSpacing: -0.2)),
        subtitle: Text(_formatDate(a.timestamp).toUpperCase(), style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 9, fontWeight: FontWeight.w900)),
        trailing: a.score != null 
          ? Text('${a.score}%', style: const TextStyle(color: FormateurTheme.success, fontWeight: FontWeight.w900)) : null,
      ),
    );
  }

  Widget _buildInformationTab() {
    final s = _profile!.stagiaire;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('COORDONNÉES', style: TextStyle(color: FormateurTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        _buildInfoCard(Icons.alternate_email_rounded, 'Email', s.email),
        _buildInfoCard(Icons.calendar_month_rounded, 'Inscrit le', _formatDate(s.createdAt)),
        _buildInfoCard(Icons.login_rounded, 'Dernière connexion', s.lastLogin != null ? _formatDate(s.lastLogin!) : 'Jamais'),
        
        const SizedBox(height: 32),
        const Text('SÉCURITÉ ET STATUT', style: TextStyle(color: FormateurTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: FormateurTheme.premiumCardDecoration.copyWith(color: FormateurTheme.textPrimary),
          child: Column(
            children: [
              const Icon(Icons.verified_user_rounded, color: FormateurTheme.accent, size: 32),
              const SizedBox(height: 16),
              const Text('PROFIL VÉRIFIÉ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text('Inscrit depuis le ${_formatDate(s.createdAt)}', style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: FormateurTheme.premiumCardDecoration,
      child: Row(
        children: [
          Icon(icon, color: FormateurTheme.accentDark, size: 20),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: FormateurTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTabState(IconData icon, String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: FormateurTheme.border)),
      child: Column(
        children: [
          Icon(icon, size: 40, color: FormateurTheme.border),
          const SizedBox(height: 12),
          Text(message.toUpperCase(), style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return date;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'quiz_completed': return Icons.emoji_events_rounded;
      case 'formation_started': return Icons.rocket_launch_rounded;
      case 'formation_completed': return Icons.check_circle_rounded;
      default: return Icons.bolt_rounded;
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: _tabBar);
  }
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
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
