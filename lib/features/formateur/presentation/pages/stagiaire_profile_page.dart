import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/stagiaire_profile_model.dart';
import 'package:wizi_learn/features/formateur/data/repositories/stagiaire_profile_repository.dart';

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
      setState(() {
        _error = 'Erreur de chargement: ${e.toString()}';
        _loading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_profile == null) return;

    final titleController = TextEditingController();
    final messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Message à ${_profile!.stagiaire.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
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
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message envoyé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF7931E)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF7931E)),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _profile == null
                  ? const Center(child: Text('Aucune donnée', style: TextStyle(color: Colors.white54)))
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
        backgroundColor: const Color(0xFFF7931E),
        icon: const Icon(Icons.send, color: Colors.black),
        label: const Text('MESSAGE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }

  Widget _buildSliverHeader() {
    final stagiaire = _profile!.stagiaire;
    final stats = _profile!.stats;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF7931E),
                    Color(0xFF1A1A1A),
                  ],
                  stops: [0.0, 0.8],
                ),
              ),
            ),
            // Profile Info Center
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    backgroundImage: stagiaire.image != null ? NetworkImage(stagiaire.image!) : null,
                    child: stagiaire.image == null
                        ? Text(
                            stagiaire.prenom[0].toUpperCase(),
                            style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  stagiaire.fullName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    stats.currentBadge,
                    style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                // Mini Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTopStat('POINTS', stats.totalPoints.toString(), const Color(0xFF00A8FF)),
                    _buildDivider(),
                    _buildTopStat('SCORE', '${stats.averageScore.toInt()}%', const Color(0xFF00D084)),
                    _buildDivider(),
                    _buildTopStat('COMPLETED', stats.formationsCompleted.toString(), const Color(0xFFF7931E)),
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
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 20,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildSliverTabs() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF7931E),
          labelColor: const Color(0xFFF7931E),
          unselectedLabelColor: Colors.white.withOpacity(0.5),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
          tabs: const [
            Tab(text: 'PROGRESS'),
            Tab(text: 'ACTIVITY'),
            Tab(text: 'INFO'),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressionTab() {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: const Color(0xFFF7931E),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'FORMATIONS EN COURS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.3), letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          if (_profile!.formations.isEmpty)
             const Padding(
               padding: EdgeInsets.symmetric(vertical: 20),
               child: Text('Aucune formation active', style: TextStyle(color: Colors.white30)),
             )
          else
            ..._profile!.formations.map((formation) => _buildFormationCard(formation)),

          const SizedBox(height: 32),

          Text(
            'HISTORIQUE DES QUIZ',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.3), letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          if (_profile!.quizHistory.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('Aucun quiz complété', style: TextStyle(color: Colors.white30)),
            )
          else
            ..._profile!.quizHistory.map((quiz) => _buildQuizCard(quiz)),
        ],
      ),
    );
  }

  Widget _buildFormationCard(dynamic formation) {
    final color = formation.isCompleted ? const Color(0xFF00D084) : const Color(0xFFF7931E);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(formation.isCompleted ? Icons.check_circle : Icons.play_circle_fill, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  formation.title.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('${formation.progress}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: formation.progress / 100,
              minHeight: 4,
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(dynamic quiz) {
    final color = quiz.percentage >= 70 ? Colors.green : quiz.percentage >= 50 ? Colors.orange : Colors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${quiz.percentage.toInt()}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  quiz.category,
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${quiz.score}/${quiz.maxScore}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatDate(quiz.completedAt),
                style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'ACTIVITÉS RÉCENTES',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.3), letterSpacing: 1),
        ),
        const SizedBox(height: 16),
        if (_profile!.activity.recentActivities.isEmpty)
          const Center(child: Text('Aucune activité récente', style: TextStyle(color: Colors.white24)))
        else
          ..._profile!.activity.recentActivities.map((activity) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF7931E).withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(_getActivityIcon(activity.type), color: const Color(0xFFF7931E), size: 20),
                  ),
                  title: Text(activity.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(_formatDate(activity.timestamp), style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                  trailing: activity.score != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text('${activity.score}%', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        )
                      : null,
                ),
              )),
      ],
    );
  }

  Widget _buildCommunicationTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'COORDONNÉES',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.3), letterSpacing: 1),
        ),
        const SizedBox(height: 16),
        _buildInfoTile(Icons.email, 'EMAIL', _profile!.stagiaire.email),
        _buildInfoTile(Icons.phone, 'TELEPHONE', 'Non renseigné'),
        const SizedBox(height: 32),
        Text(
          'NOTES PRIVÉES',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.3), letterSpacing: 1),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Icon(Icons.edit_note_outlined, color: Colors.white.withOpacity(0.2), size: 48),
              const SizedBox(height: 12),
              Text(
                'Ajouter des notes sur cet apprenant pour votre suivi personnel.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.3), size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 9, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
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
        return Icons.quiz;
      case 'formation_started':
        return Icons.play_arrow;
      case 'formation_completed':
        return Icons.check;
      default:
        return Icons.event;
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
      color: const Color(0xFF1A1A1A),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
