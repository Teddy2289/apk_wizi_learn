import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/analytics_model.dart';
import 'package:wizi_learn/features/formateur/data/models/formation_management_model.dart';
import 'package:wizi_learn/features/formateur/data/repositories/analytics_repository.dart';
import 'package:wizi_learn/features/formateur/data/repositories/formation_management_repository.dart';
import 'package:wizi_learn/features/formateur/presentation/pages/stagiaire_profile_page.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';
import 'package:wizi_learn/features/formateur/presentation/widgets/dashboard_shimmer.dart';
import 'package:wizi_learn/features/formateur/presentation/widgets/formateur_drawer_menu.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';

class FormateurDashboardPage extends StatefulWidget {
  const FormateurDashboardPage({super.key});

  @override
  State<FormateurDashboardPage> createState() => _FormateurDashboardPageState();
}

class _FormateurDashboardPageState extends State<FormateurDashboardPage> {
  late final AnalyticsRepository _analyticsRepository;
  late final FormationManagementRepository _formationRepository;
  
  DashboardSummary? _summary;
  List<InactiveStagiaire> _inactiveStagiaires = [];
  List<OnlineStagiaire> _onlineStagiaires = [];
  List<FormationWithStats> _formations = [];
  PerformanceRankings? _rankings;
  bool _loading = true;
  String? _selectedFormationId;
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
    _formationRepository = FormationManagementRepository(apiClient: apiClient);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      if (_formations.isEmpty) {
        _formations = await _formationRepository.getAvailableFormations();
      }

      final results = await Future.wait([
        _analyticsRepository.getDashboardSummary(
          period: 7,
          formationId: _selectedFormationId,
        ),
        _analyticsRepository.getInactiveStagiaires(days: 7),
        _analyticsRepository.getOnlineStagiaires(),
        _analyticsRepository.getStudentsComparison(
          formationId: _selectedFormationId,
        ),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as DashboardSummary;
          _inactiveStagiaires = results[1] as List<InactiveStagiaire>;
          _onlineStagiaires = results[2] as List<OnlineStagiaire>;
          _rankings = PerformanceRankings.fromJson(results[3] as Map<String, dynamic>);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement données: $e');
      if (mounted) setState(() => _loading = false);
    }
  }



  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormateurTheme.background,
      appBar: AppBar(
        title: const Text('Tableau de Bord'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.pushNamed(context, RouteConstants.notifications),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: FormateurDrawerMenu(
        onLogout: () async {
          // Add your logout logic here
          // final storage = const FlutterSecureStorage();
          // await storage.deleteAll();
           Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        },
      ),
      body: _loading
          ? const DashboardShimmer() 
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

                    // Online Stagiaires Section
                     _buildOnlineStagiairesSection(),
                     const SizedBox(height: 32),

                    // Formation Selector
                    if (_formations.isNotEmpty) ...[
                      const Text(
                        'FILTRER PAR FORMATION',
                        style: TextStyle(
                          color: FormateurTheme.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: FormateurTheme.border),
                          boxShadow: FormateurTheme.cardShadow,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedFormationId,
                            isExpanded: true,
                            hint: const Text('Toutes les formations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: FormateurTheme.textSecondary),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Toutes les formations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                              ..._formations.map((f) => DropdownMenuItem<String?>(
                                value: f.id.toString(),
                                child: Text(f.titre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedFormationId = value);
                              _loadData();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Top Learners Section
                    if (_rankings != null && _rankings!.mostQuizzes.isNotEmpty) ...[
                      _buildTopLearnersSection(),
                      const SizedBox(height: 40),
                    ],
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
                              : 'Inactif depuis ${_inactiveStagiaires.first.daysSinceActivity.toStringAsFixed(0)}j',
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

  Widget _buildOnlineStagiairesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(
              'EN LIGNE',
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
                color: FormateurTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_onlineStagiaires.length} ACTIFS',
                style: const TextStyle(
                  color: FormateurTheme.success,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_onlineStagiaires.isEmpty)
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
                Icon(Icons.wifi_off_rounded, color: FormateurTheme.textTertiary.withOpacity(0.5), size: 48),
                const SizedBox(height: 12),
                 Text(
                  'Aucun apprenant en ligne',
                  style: TextStyle(color: FormateurTheme.textSecondary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _onlineStagiaires.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final stagiaire = _onlineStagiaires[index];

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StagiaireProfilePage(
                          stagiaireId: stagiaire.id,
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
                    child: Row(
                      children: [
                         Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: FormateurTheme.success, width: 2),
                          ),
                           child: CircleAvatar(
                              radius: 22,
                              backgroundColor: FormateurTheme.background,
                              backgroundImage: stagiaire.avatar != null && stagiaire.avatar!.isNotEmpty
                                ? NetworkImage(AppConstants.getUserImageUrl(stagiaire.avatar!)) 
                                : null,
                              child: stagiaire.avatar == null
                                ? Text(
                                    stagiaire.prenom.isNotEmpty ? stagiaire.prenom[0].toUpperCase() : '?',
                                    style: TextStyle(color: FormateurTheme.textPrimary, fontWeight: FontWeight.w900),
                                  )
                                : null,
                            ),
                         ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${stagiaire.prenom} ${stagiaire.nom}',
                                style: const TextStyle(
                                  color: FormateurTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stagiaire.email,
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                             Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: FormateurTheme.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: FormateurTheme.border),
                              ),
                              child: Text(
                                stagiaire.lastActivityAt,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: FormateurTheme.textSecondary,
                                ),
                              ),
                            ),
                            if (stagiaire.formations.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                stagiaire.formations.first,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: FormateurTheme.textTertiary,
                                ),
                              ),
                            ]
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

  Widget _buildTopLearnersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(
              'TOP PERFORMANCE',
              style: TextStyle(
                color: FormateurTheme.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
             Text(
              '30 DERNIERS JOURS',
              style: TextStyle(
                color: FormateurTheme.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: FormateurTheme.border),
            boxShadow: FormateurTheme.cardShadow,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: FormateurTheme.orangeAccent, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Meilleurs Score Quiz',
                    style: TextStyle(
                      color: FormateurTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...(_rankings?.mostQuizzes.take(3).map((s) => _buildTopLearnerItem(s)) ?? []),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopLearnerItem(StagiairePerformance s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            backgroundColor: FormateurTheme.accent.withOpacity(0.1),
            backgroundImage: s.image != null && s.image!.isNotEmpty 
                ? NetworkImage(AppConstants.getUserImageUrl(s.image!)) 
                : null,
            child: s.image == null
                ? Text(
                    s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: FormateurTheme.accentDark, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name,
                  style: const TextStyle(
                    color: FormateurTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${s.totalQuizzes} quiz complétés',
                  style: const TextStyle(
                    color: FormateurTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FormateurTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.flash_on_rounded, color: Colors.blue, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${s.totalLogins}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
