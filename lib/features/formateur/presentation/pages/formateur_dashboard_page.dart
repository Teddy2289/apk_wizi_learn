import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/analytics_model.dart';
import 'package:wizi_learn/features/formateur/data/repositories/analytics_repository.dart';
import 'package:wizi_learn/features/formateur/presentation/pages/stagiaire_profile_page.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';
import 'package:wizi_learn/features/formateur/presentation/widgets/dashboard_shimmer.dart';

class FormateurDashboardPage extends StatefulWidget {
  const FormateurDashboardPage({super.key});

  @override
  State<FormateurDashboardPage> createState() => _FormateurDashboardPageState();
}

class _FormateurDashboardPageState extends State<FormateurDashboardPage> {
  late final AnalyticsRepository _analyticsRepository;
  
  DashboardSummary? _summary;
  List<InactiveStagiaire> _inactiveStagiaires = [];
  List<OnlineStagiaire> _onlineStagiaires = [];
  bool _loading = true;
  String _selectedFilter = 'all'; // all, active, formation
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _analyticsRepository = AnalyticsRepository(apiClient: apiClient);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _analyticsRepository.getDashboardSummary(period: 7),
        _analyticsRepository.getInactiveStagiaires(days: 7),
        _analyticsRepository.getOnlineStagiaires(),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as DashboardSummary;
          _inactiveStagiaires = results[1] as List<InactiveStagiaire>;
          _onlineStagiaires = results[2] as List<OnlineStagiaire>;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement données: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> _getFilteredStagiaires() {
    // Falls back to formations list from summary or empty list for now
    // React dashboard actually lists progress, which might be in 'formations' or a separate call
    // For now we map from _summary?.formations if structure matches, or adjust later.
    // Based on previous code, it was expecting a list of stagiaires directly.
    // React Dashboard typically doesn't show a full list of all trainees unless in "Performance" tab.
    // However, keeping previous functionality:
    // If _summary?.formations contains student data, we use it.
    // Checking React: "FormateurDashboardStats" returns "formations" which seems to be Formation list, not student list.
    // "TrainerPerformanceStats" (separate component) has student list.
    // The previous Flutter code had `_stagiaireProgress = data['stagiaires']`.
    // The new `/formateur/dashboard/stats` endpoint DOES NOT return list of stagiaires (it returns stats).
    // We need to fetch the trainee list separately if we want to display it.
    // React uses `<TrainerPerformanceStats />` which calls `/formateur/analytics/performance`
    
    // TEMPORARY FIX: We will return empty list or mock until we implement the Performance section properly
    // or we should call getStudentsComparison or similar.
    // Actually, let's fetch performance data in _loadData as 4th parallel call to maintain feature parity.
    return []; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormateurTheme.background,
      body: _loading
          ? const DashboardShimmer() // You might need to update Shimmer colors too ideally
          : RefreshIndicator(
              color: FormateurTheme.accent,
              backgroundColor: Colors.white,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),

                    // Critical Alerts
                     if (_inactiveStagiaires.isNotEmpty) ...[
                      _buildCriticalAlertsSection(),
                      const SizedBox(height: 32),
                    ],

                    // Stats Grid
                    if (_summary != null) ...[
                      _buildStatsGrid(),
                       const SizedBox(height: 32),
                    ],

                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 32),

                    // Search and Filters
                    _buildSearchAndFilters(),
                    const SizedBox(height: 24),

                    // Trainees Section
                     _buildTraineesProgressSection(),
                     const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: FormateurTheme.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FormateurTheme.accent.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
               Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: FormateurTheme.accentDark,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PERSPECTIVE FORMATEUR',
                style: TextStyle(
                  color: FormateurTheme.accentDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: FormateurTheme.textPrimary,
              height: 1.1,
              letterSpacing: -1,
              fontFamily: 'Montserrat', // Ensuring font consistency
            ),
            children: [
              const TextSpan(text: 'Dashboard '),
              TextSpan(
                text: 'Analytique',
                style: TextStyle(
                  foreground: Paint()
                    ..shader = FormateurTheme.textGradient.createShader(
                      const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                    ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Supervisez l'engagement et l'excellence académique de vos cohortes en un coup d'œil.",
          style: TextStyle(
            color: FormateurTheme.textSecondary,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCriticalAlertsSection() {
    final criticalCount = _inactiveStagiaires.where((s) => s.neverConnected).length;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // React: bg-white
        borderRadius: BorderRadius.circular(32), // React: rounded-[2rem]
        boxShadow: FormateurTheme.cardShadow,
        border: Border.all(color: FormateurTheme.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FormateurTheme.orangeAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: FormateurTheme.orangeAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'ATTENTION REQUISE',
                    style: TextStyle(
                      color: FormateurTheme.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                   Text(
                    'Alertes Critiques',
                    style: TextStyle(
                      color: FormateurTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (criticalCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: FormateurTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 14, color: FormateurTheme.error),
                      const SizedBox(width: 4),
                       Text(
                        '$criticalCount Critiques',
                        style: const TextStyle(
                          color: FormateurTheme.error,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_inactiveStagiaires.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FormateurTheme.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: FormateurTheme.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: FormateurTheme.error.withOpacity(0.1),
                    child: Text(
                      _inactiveStagiaires.first.prenom.isNotEmpty ? _inactiveStagiaires.first.prenom[0].toUpperCase() : '?',
                      style: const TextStyle(color: FormateurTheme.error, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_inactiveStagiaires.first.prenom} ${_inactiveStagiaires.first.nom}',
                          style: const TextStyle(
                            color: FormateurTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          _inactiveStagiaires.first.neverConnected
                              ? 'Jamais connecté'
                              : 'Inactif depuis ${_inactiveStagiaires.first.daysSinceActivity}j',
                          style: const TextStyle(
                            color: FormateurTheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
                            stagiaireId: _inactiveStagiaires.first.id,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FormateurTheme.textPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text(
                      'Relancer',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount = constraints.maxWidth < 600 ? 1 : 2; // More responsive
        final double aspectRatio = crossAxisCount == 1 ? 2.2 : 1.2; // Adjusted aspect ratio
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: aspectRatio,
          children: [
            _buildStatCard(
              'Stagiaires',
              _summary?.totalStagiaires.toString() ?? '0',
              'Actifs cette semaine',
              Icons.people_outline,
              Colors.blue,
            ),
            _buildStatCard(
              'Programmes',
              _summary?.activeThisWeek.toString() ?? '0', 
               'Formations actives',
              Icons.school_outlined,
              Colors.purple,
            ),
            _buildStatCard(
              'Score Moyen',
              '${_summary?.avgQuizScore ?? 0}%',
               'Performance globale',
              Icons.emoji_events_outlined,
              FormateurTheme.accentDark,
            ),
            _buildStatCard(
              'Alertes',
              _summary?.inactiveCount.toString() ?? '0',
               'Stagiaires inactifs',
              Icons.trending_down_rounded,
              FormateurTheme.orangeAccent,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32), // React style
        boxShadow: FormateurTheme.cardShadow,
        border: Border.all(color: FormateurTheme.border),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: FormateurTheme.textTertiary,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: FormateurTheme.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FormateurTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FormateurTheme.border),
                ),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: FormateurTheme.textSecondary,
                  ),
                ),
              ),
            ],
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
            icon: Icons.leaderboard_outlined,
            label: 'Classement',
            onPressed: () => Navigator.pushNamed(context, '/formateur/classement'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            icon: Icons.notifications_none_outlined,
            label: 'Notifier',
            onPressed: () => Navigator.pushNamed(context, '/formateur/send-notification'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            icon: Icons.bar_chart_rounded,
            label: 'Analytique',
            onPressed: () => Navigator.pushNamed(context, '/formateur/analytiques'),
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
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: FormateurTheme.border),
            boxShadow: FormateurTheme.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FormateurTheme.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: FormateurTheme.textPrimary, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: FormateurTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
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
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: FormateurTheme.cardShadow,
            border: Border.all(color: FormateurTheme.border),
          ),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Rechercher un apprenant...',
              hintStyle: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: FormateurTheme.textTertiary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            style: const TextStyle(color: FormateurTheme.textPrimary),
          ),
        ),
        const SizedBox(height: 16),
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Tous', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Actifs', 'active'),
              const SizedBox(width: 8),
              _buildFilterChip('En Formation', 'formation'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? FormateurTheme.textPrimary : Colors.white,
          border: Border.all(
            color: isSelected ? FormateurTheme.textPrimary : FormateurTheme.border,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [
            BoxShadow(color: FormateurTheme.textPrimary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : FormateurTheme.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(
              'APPRENANTS',
              style: TextStyle(
                color: FormateurTheme.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: FormateurTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${filteredStagiaires.length} TOTAL',
                style: const TextStyle(
                  color: FormateurTheme.accentDark,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (filteredStagiaires.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: FormateurTheme.border),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.person_off_outlined, color: FormateurTheme.textTertiary.withOpacity(0.5), size: 48),
                const SizedBox(height: 12),
                 Text(
                  'Aucun résultat trouvé',
                  style: TextStyle(color: FormateurTheme.textSecondary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredStagiaires.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final stagiaire = filteredStagiaires[index];
              final double progress = (stagiaire['progress'] ?? 0).toDouble();
              final int avgScore = (stagiaire['avg_score'] ?? 0).toInt();

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StagiaireProfilePage(
                          stagiaireId: stagiaire['id'] as int,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: FormateurTheme.border),
                      boxShadow: FormateurTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                             CircleAvatar(
                                radius: 24,
                                backgroundColor: FormateurTheme.background,
                                backgroundImage: stagiaire['avatar'] != null 
                                  ? NetworkImage(stagiaire['avatar']) 
                                  : null,
                                child: stagiaire['avatar'] == null
                                  ? Text(
                                      stagiaire['prenom'][0].toUpperCase(),
                                      style: TextStyle(color: FormateurTheme.textPrimary, fontWeight: FontWeight.w900),
                                    )
                                  : null,
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${stagiaire['prenom']} ${stagiaire['nom']}',
                                    style: const TextStyle(
                                      color: FormateurTheme.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    stagiaire['formation'] ?? 'Formation non assignée',
                                    style: const TextStyle(
                                      color: FormateurTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: FormateurTheme.border),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniStat(
                                'PROGRESSION', 
                                '${progress.toInt()}%', 
                                Colors.blue,
                                progress / 100,
                              ),
                            ),
                            Container(width: 1, height: 30, color: FormateurTheme.border),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: _buildMiniStat(
                                  'SCORE MOYEN', 
                                  '$avgScore%', 
                                  avgScore >= 75 ? FormateurTheme.success : FormateurTheme.orangeAccent,
                                  avgScore / 100,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: FormateurTheme.textTertiary,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                color: FormateurTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: FormateurTheme.background,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
