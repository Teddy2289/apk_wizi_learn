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
      appBar: AppBar(
        title: Text(_profile?.stagiaire.fullName ?? 'Profil Stagiaire'),
        backgroundColor: const Color(0xFFF7931E),
        actions: [
          if (_profile != null)
            IconButton(
              icon: const Icon(Icons.mail),
              onPressed: _sendMessage,
              tooltip: 'Envoyer un message',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _profile == null
                  ? const Center(child: Text('Aucune donnée'))
                  : Column(
                      children: [
                        // Header Section
                        _buildProfileHeader(),
                        // Stats Overview
                        _buildStatsOverview(),
                        // Tabs
                        TabBar(
                          controller: _tabController,
                          labelColor: const Color(0xFFF7931E),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: const Color(0xFFF7931E),
                          tabs: const [
                            Tab(text: 'Progression', icon: Icon(Icons.trending_up)),
                            Tab(text: 'Engagement', icon: Icon(Icons.calendar_today)),
                            Tab(text: 'Communication', icon: Icon(Icons.message)),
                          ],
                        ),
                        // Tab Views
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildProgressionTab(),
                              _buildEngagementTab(),
                              _buildCommunicationTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildProfileHeader() {
    final stagiaire = _profile!.stagiaire;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFF7931E),
            backgroundImage:
                stagiaire.image != null ? NetworkImage(stagiaire.image!) : null,
            child: stagiaire.image == null
                ? Text(
                    stagiaire.prenom[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stagiaire.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  stagiaire.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      _profile!.stats.currentBadge,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                if (stagiaire.lastLogin != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: _isRecentlyActive() ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isRecentlyActive()
                            ? 'Actif'
                            : 'Dernière connexion: ${_formatDate(stagiaire.lastLogin!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    final stats = _profile!.stats;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            icon: Icons.people_alt,
            label: 'Total Points',
            value: stats.totalPoints.toString(),
            color: Colors.blue,
          ),
          _buildStatCard(
            icon: Icons.star,
            label: 'Avg Score',
            value: '${stats.averageScore.toStringAsFixed(1)}%',
            color: Colors.amber,
          ),
          _buildStatCard(
            icon: Icons.check_circle,
            label: 'Complété',
            value: stats.formationsCompleted.toString(),
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressionTab() {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Formations Section
          const Text(
            'FORMATIONS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ..._profile!.formations.map((formation) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    formation.isCompleted
                        ? Icons.check_circle
                        : Icons.play_circle_outline,
                    color: formation.isCompleted ? Colors.green : Colors.orange,
                  ),
                  title: Text(formation.title),
                  subtitle: LinearProgressIndicator(
                    value: formation.progress / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      formation.isCompleted ? Colors.green : Colors.orange,
                    ),
                  ),
                  trailing: Text('${formation.progress}%'),
                ),
              )),

          const SizedBox(height: 16),

          // Quiz History Section
          const Text(
            'QUIZ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ..._profile!.quizHistory.map((quiz) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: quiz.percentage >= 70
                        ? Colors.green
                        : quiz.percentage >= 50
                            ? Colors.orange
                            : Colors.red,
                    child: Text(
                      '${quiz.percentage.toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(quiz.title),
                  subtitle: Text(quiz.category),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${quiz.score}/${quiz.maxScore}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDate(quiz.completedAt),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildEngagementTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'ACTIVITÉ (30 derniers jours)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        // Simple activity calendar placeholder
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              '📅 Calendrier d\'activité\n(à implémenter)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'ACTIVITÉS RÉCENTES',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ..._profile!.activity.recentActivities.map((activity) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  _getActivityIcon(activity.type),
                  color: const Color(0xFFF7931E),
                ),
                title: Text(activity.title),
                subtitle: Text(_formatDate(activity.timestamp)),
                trailing: activity.score != null
                    ? Chip(
                        label: Text('${activity.score}%'),
                        backgroundColor: Colors.green[50],
                      )
                    : null,
              ),
            )),
      ],
    );
  }

  Widget _buildCommunicationTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          onPressed: _sendMessage,
          icon: const Icon(Icons.send),
          label: const Text('Envoyer un message'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF7931E),
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'NOTES DU FORMATEUR',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              '📝 Notes privées\n(à implémenter)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  bool _isRecentlyActive() {
    if (_profile?.stagiaire.lastLogin == null) return false;
    // Consider active if logged in within last 24 hours
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
