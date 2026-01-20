import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/presentation/pages/stagiaire_profile_page.dart';
import 'package:wizi_learn/features/formateur/presentation/widgets/alerts_widget.dart';
import 'package:wizi_learn/features/formateur/presentation/widgets/dashboard_shimmer.dart';

class FormateurDashboardPage extends StatefulWidget {
  const FormateurDashboardPage({super.key});

  @override
  State<FormateurDashboardPage> createState() => _FormateurDashboardPageState();
}

class _FormateurDashboardPageState extends State<FormateurDashboardPage> {
  final ApiClient _apiClient = ApiClient(
    dio: Dio(),
    storage: const FlutterSecureStorage(),
  );

  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _trends;
  List<dynamic> _inactiveStagiaires = [];
  List<dynamic> _stagiaireProgress = [];
  bool _loading = true;
  String _selectedFilter = 'all'; // all, active, formation
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Consolidated API call - reduces 4 network requests to 1
      final response = await _apiClient.get('/formateur/dashboard/home?days=7');
      final data = response.data;

      setState(() {
        _stats = data['stats'];
        _inactiveStagiaires = data['inactive_stagiaires'] ?? [];
        _trends = data['trends'];
        _stagiaireProgress = data['stagiaires'] ?? [];
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement données: $e');
      setState(() => _loading = false);
    }
  }

  List<dynamic> _getFilteredStagiaires() {
    List<dynamic> filtered = _stagiaireProgress;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((s) {
        final name = '${s['prenom']} ${s['nom']}'.toLowerCase();
        final email = (s['email'] as String).toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    // Apply status filter
    if (_selectedFilter == 'active') {
      filtered = filtered
          .where((s) => (s['is_active'] ?? false) == true)
          .toList();
    } else if (_selectedFilter == 'formation') {
      filtered = filtered
          .where((s) => (s['in_formation'] ?? false) == true)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Dashboard Formateur'),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: _loading
          ? const DashboardShimmer()
          : RefreshIndicator(
              color: const Color(0xFFF7931E),
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Critical Alerts Section
                    if (_inactiveStagiaires.isNotEmpty) ...[
                      _buildCriticalAlertsSection(),
                      const SizedBox(height: 24),
                    ],

                    // Stats Cards Grid
                    if (_stats != null) ...[
                      _buildStatsGrid(),
                      const SizedBox(height: 24),
                    ],

                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 24),

                    // Search and Filters
                    _buildSearchAndFilters(),
                    const SizedBox(height: 16),

                    // Trainees Progress Section
                    _buildTraineesProgressSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCriticalAlertsSection() {
    final criticalCount = _inactiveStagiaires.where((s) => s['never_connected'] == true).length;
    
    return Card(
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Text(
                  'CRITICAL ALERTS',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${criticalCount} Active',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_inactiveStagiaires.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A2A2A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Text(
                            _inactiveStagiaires.first['prenom'][0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_inactiveStagiaires.first['prenom']} ${_inactiveStagiaires.first['nom']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _inactiveStagiaires.first['never_connected'] == true
                                    ? 'Jamais connecté'
                                    : 'Inactif depuis ${_inactiveStagiaires.first['days_since_activity']}j',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StagiaireProfilePage(
                                  stagiaireId: _inactiveStagiaires.first['id'] as int,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text(
                            'Follow Up Now',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use 1 column on very small screens (< 320px), 2 otherwise
        final int crossAxisCount = constraints.maxWidth < 320 ? 1 : 2;
        final double aspectRatio = crossAxisCount == 1 ? 2.5 : 1.3;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          children: [
            _buildStatCard(
              'Total Stagiaires',
              _stats!['total_stagiaires'].toString(),
              Icons.people,
              const Color(0xFF00A8FF),
            ),
            _buildStatCard(
              'Actifs (7j)',
              _stats!['active_this_week'].toString(),
              Icons.trending_up,
              const Color(0xFF00D084),
            ),
            _buildStatCard(
              'Score Moyen',
              '${_stats!['avg_quiz_score']}%',
              Icons.emoji_events,
              const Color(0xFFFFA500),
            ),
            _buildStatCard(
              'Inactifs',
              _stats!['inactive_count'].toString(),
              Icons.trending_down,
              const Color(0xFFFF6B6B),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.leaderboard,
            label: 'Classement',
            onPressed: () => Navigator.pushNamed(context, '/formateur/classement'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.announcement,
            label: 'Annonces',
            onPressed: () => Navigator.pushNamed(context, '/formateur/send-notification'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.analytics,
            label: 'Analytics',
            onPressed: () => Navigator.pushNamed(context, '/formateur/analytics'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFF7931E), size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search trainees...',
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 12),
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All Trainees', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Active', 'active'),
              const SizedBox(width: 8),
              _buildFilterChip('Formation', 'formation'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF7931E) : const Color(0xFF2A2A2A),
            border: Border.all(
              color: isSelected ? const Color(0xFFF7931E) : Colors.grey.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTraineesProgressSection() {
    final filteredStagiaires = _getFilteredStagiaires();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Trainee Progress',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              'Detailed View →',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (filteredStagiaires.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: const Text(
              'Aucun stagiaire trouvé',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredStagiaires.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final stagiaire = filteredStagiaires[index];
              final progress = (stagiaire['progress'] ?? 0).toDouble();
              final avgScore = (stagiaire['avg_score'] ?? 0).toInt();

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StagiaireProfilePage(
                        stagiaireId: stagiaire['id'] as int,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _getStatusColor(stagiaire),
                            child: Text(
                              stagiaire['prenom'][0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${stagiaire['prenom']} ${stagiaire['nom']}'
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  stagiaire['formation'] ?? 'N/A',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'AVG SCORE',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      'PENDING',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$avgScore%',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${stagiaire['modules_count']} Modules',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progress / 100,
                                  strokeWidth: 4,
                                  backgroundColor: Colors.grey.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getProgressColor(progress),
                                  ),
                                ),
                                Text(
                                  '${progress.toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Color _getStatusColor(dynamic stagiaire) {
    if (stagiaire['never_connected'] == true) return Colors.red;
    if (stagiaire['is_active'] == true) return Colors.green;
    return Colors.orange;
  }

  Color _getProgressColor(double progress) {
    if (progress >= 75) return Colors.green;
    if (progress >= 50) return Colors.blue;
    if (progress >= 25) return Colors.orange;
    return Colors.red;
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StagiaireProfilePage(
                          stagiaireId: stagiaire['id'] as int,
                        ),
                      ),
                    );
                  },
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

  Widget _buildTrendsSummary() {
    final quizTrends = _trends?['quiz_trends'] as List<dynamic>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tendances des quiz (30j)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (quizTrends.isEmpty)
              const Center(child: Text('Aucune donnée de tendance'))
            else
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: quizTrends.take(10).map((t) {
                    final double score = (t['avg_score'] ?? 0).toDouble();
                    // Scale score 0-100 to height 0-80
                    final double height = (score / 100) * 80;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 20,
                          height: height > 5 ? height : 5, // Min height
                          color: Colors.green.withOpacity(0.6),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t['date'].toString().substring(8),
                          style: const TextStyle(fontSize: 8),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
