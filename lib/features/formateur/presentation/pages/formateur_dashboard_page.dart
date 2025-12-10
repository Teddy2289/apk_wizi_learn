import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

class FormateurDashboardPage extends StatefulWidget {
  const FormateurDashboardPage({Key? key}) : super(key: key);

  @override
  State<FormateurDashboardPage> createState() => _FormateurDashboardPageState();
}

class _FormateurDashboardPageState extends State<FormateurDashboardPage> {
  final ApiClient _apiClient = ApiClient(
    dio: Dio(),
    storage: const FlutterSecureStorage(),
  );

  Map<String, dynamic>? _stats;
  List<dynamic> _inactiveStagiaires = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final stats = await _apiClient.get('/formateur/dashboard/stats');
      final inactive = await _apiClient.get('/formateur/stagiaires/inactive?days=7');

      setState(() {
        _stats = stats.data;
        _inactiveStagiaires = inactive.data['inactive_stagiaires'] ?? [];
        _loading = false;
      });
    } catch (e) {
      print('Erreur chargement données: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Formateur'),
        backgroundColor: const Color(0xFFF7931E),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards Grid
                    if (_stats != null) ...[
                      _buildStatsGrid(),
                      const SizedBox(height: 24),
                    ],

                    // Alertes Stagiaires Inactifs
                    _buildInactiveStagiairesList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          'Total Stagiaires',
          _stats!['total_stagiaires'].toString(),
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Actifs (7j)',
          _stats!['active_this_week'].toString(),
          Icons.trending_up,
          Colors.green,
        ),
        _buildStatCard(
          'Score Moyen',
          '${_stats!['avg_quiz_score']}%',
          Icons.emoji_events,
          Colors.amber,
        ),
        _buildStatCard(
          'Inactifs',
          _stats!['inactive_count'].toString(),
          Icons.trending_down,
          Colors.orange,
        ),
        _buildStatCard(
          'Jamais Connectés',
          _stats!['never_connected'].toString(),
          Icons.warning,
          Colors.red,
        ),
        _buildStatCard(
          'Heures Vidéos',
          '${_stats!['total_video_hours']}h',
          Icons.video_library,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInactiveStagiairesList() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Stagiaires Inactifs (${_inactiveStagiaires.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_inactiveStagiaires.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'Aucun stagiaire inactif 🎉',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _inactiveStagiaires.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final stagiaire = _inactiveStagiaires[index];
                final daysInactive = stagiaire['days_since_activity'];
                final neverConnected = stagiaire['never_connected'] ?? false;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: neverConnected ? Colors.red : Colors.orange,
                    child: Text(
                      stagiaire['prenom'][0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text('${stagiaire['prenom']} ${stagiaire['nom']}'),
                  subtitle: Text(stagiaire['email']),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (neverConnected)
                        const Chip(
                          label: Text(
                            'Jamais connecté',
                            style: TextStyle(fontSize: 10),
                          ),
                          backgroundColor: Colors.red,
                          labelStyle: TextStyle(color: Colors.white),
                        )
                      else
                        Chip(
                          label: Text(
                            'Il y a ${daysInactive}j',
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: Colors.orange.shade100,
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
