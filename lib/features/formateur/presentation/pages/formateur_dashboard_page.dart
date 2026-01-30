import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/analytics_model.dart';
import 'package:wizi_learn/features/formateur/data/models/formation_management_model.dart';
import 'package:wizi_learn/features/formateur/data/models/agenda_model.dart';
import 'package:wizi_learn/features/formateur/data/repositories/analytics_repository.dart';
import 'package:wizi_learn/features/formateur/data/repositories/formation_management_repository.dart';
import 'package:wizi_learn/features/formateur/data/repositories/agenda_repository.dart';
import 'package:wizi_learn/features/formateur/presentation/pages/stagiaire_profile_page.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';
import 'package:wizi_learn/features/formateur/presentation/widgets/dashboard_footer.dart';
import 'package:wizi_learn/features/formateur/presentation/widgets/dashboard_shimmer.dart';
import 'package:wizi_learn/features/formateur/presentation/widgets/formateur_drawer_menu.dart';
import 'package:wizi_learn/features/formateur/presentation/widgets/online_stagiaires_card.dart';
import 'package:wizi_learn/features/formateur/presentation/widgets/formations_view_card.dart';
import 'package:wizi_learn/features/formateur/presentation/widgets/formateur_view_card.dart';
import 'package:wizi_learn/features/formateur/presentation/widgets/inactive_stagiaires_table.dart';
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
  late final AgendaRepository _agendaRepository;
  
  DashboardSummary? _summary;
  List<InactiveStagiaire> _inactiveStagiaires = [];
  List<OnlineStagiaire> _onlineStagiaires = [];
  PerformanceRankings? _rankings;
  bool _loading = true;
  
  // Pagination states for middle section cards
  int _formationsPage = 1;
  int _formationsLastPage = 1;
  int _formationsTotal = 0;
  List<FormationDashboardStats> _paginatedFormations = [];
  
  int _formateursPage = 1;
  int _formateursLastPage = 1;
  int _formateursTotal = 0;
  List<Map<String, dynamic>> _paginatedFormateurs = [];

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _analyticsRepository = AnalyticsRepository(apiClient: apiClient);
    _formationRepository = FormationManagementRepository(apiClient: apiClient);
    _agendaRepository = AgendaRepository(apiClient: apiClient);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _analyticsRepository.getDashboardSummary(
          period: 30,
          formationsPage: _formationsPage,
          formateursPage: _formateursPage,
        ),
        _analyticsRepository.getInactiveStagiaires(days: 7),
        _analyticsRepository.getOnlineStagiaires(),
        _analyticsRepository.getStudentsComparison(),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as DashboardSummary;
          _inactiveStagiaires = results[1] as List<InactiveStagiaire>;
          _onlineStagiaires = results[2] as List<OnlineStagiaire>;
          _rankings = PerformanceRankings.fromJson(results[3] as Map<String, dynamic>);
          
          // Update pagination state from summary metadata
          if (_summary != null) {
            _formationsTotal = _summary!.formationsMeta.total;
            _formationsLastPage = _summary!.formationsMeta.lastPage;
            // The formations list is already the current page data
            _paginatedFormations = _summary!.formations;
            
            _formateursTotal = _summary!.formateursMeta.total;
            _formateursLastPage = _summary!.formateursMeta.lastPage;
            _paginatedFormateurs = _summary!.formateurs.cast<Map<String, dynamic>>();
          }
          
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement données: $e');
      if (mounted) setState(() => _loading = false);
    }
  }
  
  void _onFormationsPageChanged(int page) {
    if (page < 1 || page > _formationsLastPage) return;
    setState(() => _formationsPage = page);
    _loadData();
  }
  
  void _onFormateursPageChanged(int page) {
    if (page < 1 || page > _formateursLastPage) return;
    setState(() => _formateursPage = page);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormateurTheme.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: FormateurTheme.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: FormateurTheme.textPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          fontFamily: 'Montserrat',
          letterSpacing: -0.5,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: FormateurTheme.border, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 22),
            onPressed: () => Navigator.pushNamed(context, RouteConstants.notifications),
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: FormateurDrawerMenu(
        onLogout: () async {
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
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPremiumHeader(),
                    
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Stats Grid
                          if (_summary != null) ...[
                            _buildStatsGrid(),
                            const SizedBox(height: 64),
                          ],

                          // 3-Column Middle Section (Matching React)
                          _build3ColumnMiddleSection(),
                          const SizedBox(height: 64),

                          // Performance & Engagement Section
                          if (_rankings != null) _buildPerformanceSection(),
                          const SizedBox(height: 64),

                          // Inactive Stagiaires Table
                          InactiveStagiairesTable(
                            stagiaires: _inactiveStagiaires,
                            loading: false,
                          ),
                        ],
                      ),
                    ),
                    
                    // Footer
                    // const DashboardFooter(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: FormateurTheme.border)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: FormateurTheme.accent.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: FormateurTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: FormateurTheme.accent.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.analytics_outlined, size: 12, color: FormateurTheme.accentDark),
                    const SizedBox(width: 8),
                    Text(
                      'Espace Formateur',
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
              const SizedBox(height: 24),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: FormateurTheme.textPrimary,
                    height: 1.0,
                    letterSpacing: -1.5,
                    fontFamily: 'Montserrat',
                  ),
                  children: [
                    TextSpan(text: 'Tableau\n'),
                    TextSpan(
                      text: 'de bord',
                      style: TextStyle(color: FormateurTheme.accentDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Supervisez l'engagement et l'excellence académique de vos stagiaires.",
                style: TextStyle(
                  color: FormateurTheme.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalAlertsSection() {
    final criticalCount = _inactiveStagiaires.where((s) => s.neverConnected).length;
    
    return Container(
      decoration: FormateurTheme.premiumCardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FormateurTheme.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: FormateurTheme.orangeAccent, size: 22),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attention',
                    style: TextStyle(
                      color: FormateurTheme.orangeAccent,
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
                      fontWeight: FontWeight.w900,
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
                  child: Text(
                    '$criticalCount',
                    style: const TextStyle(color: FormateurTheme.error, fontWeight: FontWeight.bold, fontSize: 12),
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
                    backgroundColor: Colors.white,
                    backgroundImage: _inactiveStagiaires.first.avatar != null && _inactiveStagiaires.first.avatar!.isNotEmpty
                        ? NetworkImage(AppConstants.getUserImageUrl(_inactiveStagiaires.first.avatar!))
                        : null,
                    child: (_inactiveStagiaires.first.avatar == null || _inactiveStagiaires.first.avatar!.isEmpty)
                        ? Text(
                            _inactiveStagiaires.first.prenom.isNotEmpty ? _inactiveStagiaires.first.prenom[0].toUpperCase() : '?',
                            style: const TextStyle(color: FormateurTheme.accentDark, fontWeight: FontWeight.w900),
                          )
                        : null,
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
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _inactiveStagiaires.first.neverConnected
                              ? 'Jamais connecté'
                              : 'Inactif depuis ${_inactiveStagiaires.first.daysSinceActivity.toStringAsFixed(0)}j',
                          style: const TextStyle(
                            color: FormateurTheme.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
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
                    style: TextButton.styleFrom(
                      foregroundColor: FormateurTheme.accentDark,
                      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                    child: const Text('Voir profil'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        _buildStatCard(
          'Stagiaires', 
          _summary?.totalStagiaires.toString() ?? '0', 
          Icons.people_alt_rounded, 
          Colors.blue,
          subValue: '${_summary?.activeThisWeek ?? 0} actifs'
        ),
        _buildStatCard(
          'Formations', 
          _summary?.totalFormations.toString() ?? '0', 
          Icons.video_library_rounded, 
          Colors.purple,
          subValue: 'Programmes actifs'
        ),
        _buildStatCard(
          'Quiz Complétés', 
          _summary?.totalQuizzesTaken.toString() ?? '0', 
          Icons.emoji_events_rounded, 
          FormateurTheme.accentDark,
          subValue: 'Moyenne: ${_summary?.avgQuizScore ?? 0}%'
        ),
        _buildStatCard(
          'Inactifs', 
          _summary?.inactiveCount.toString() ?? '0', 
          Icons.notifications_active_rounded, 
          FormateurTheme.orangeAccent,
          subValue: '7+ jours d\'absence'
        ),
        _buildStatCard(
          'Jamais Connectés', 
          _summary?.neverConnected.toString() ?? '0', 
          Icons.person_off_rounded, 
          FormateurTheme.error,
          subValue: 'En attente'
        ),
        _buildStatCard(
          'Heures Vidéos', 
          '${_summary?.totalVideoHours.toStringAsFixed(0) ?? 0}h', 
          Icons.play_circle_fill_rounded, 
          Colors.indigo,
          subValue: 'Visionnage cumulé'
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? subValue}) {
    return Container(
      decoration: FormateurTheme.premiumCardDecoration,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
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
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: FormateurTheme.textPrimary, letterSpacing: -1),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 0.5),
              ),
              if (subValue != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.1)),
                  ),
                  child: Text(
                    subValue,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildFormationPerformanceSection() {
    if (_summary?.formations.isEmpty ?? true) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             const Text(
               'Performance par formation',
               style: TextStyle(color: FormateurTheme.textTertiary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
             ),
             Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('${_summary!.formations.length}', style: const TextStyle(color: Colors.indigo, fontSize: 9, fontWeight: FontWeight.w900)),
             ),
           ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _summary!.formations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final f = _summary!.formations[index];
              return Container(
                width: 260,
                padding: const EdgeInsets.all(20),
                decoration: FormateurTheme.premiumCardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            f.titre,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: FormateurTheme.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: f.avgScore >= 80 ? Colors.green.withOpacity(0.1) : (f.avgScore >= 50 ? FormateurTheme.accent.withOpacity(0.1) : FormateurTheme.error.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${f.avgScore}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: f.avgScore >= 80 ? Colors.green : (f.avgScore >= 50 ? FormateurTheme.accentDark : FormateurTheme.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        _buildFormationStatRow(Icons.people_outline, '${f.studentCount} Stagiaires'),
                        const SizedBox(height: 8),
                         _buildFormationStatRow(Icons.check_circle_outline, '${f.totalCompletions} Quiz finis'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFormationStatRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: FormateurTheme.textTertiary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: FormateurTheme.textSecondary,
          ),
        ),
      ],
    );
  }


  Widget _buildTopLearnersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top performance',
          style: TextStyle(color: FormateurTheme.textTertiary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        const SizedBox(height: 20),
        DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: FormateurTheme.border),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: FormateurTheme.accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: FormateurTheme.textTertiary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                  tabs: const [
                    Tab(text: 'Top Quiz'),
                    Tab(text: 'Top Actifs'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 300, 
                child: TabBarView(
                  children: [
                    // Top Quiz List
                    ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: (_rankings?.mostQuizzes.take(3).map((s) => _buildTopLearnerItem(s, type: 'quiz')) ?? []).toList(),
                    ),
                    // Top Active List
                    ListView(
                       physics: const NeverScrollableScrollPhysics(),
                       children: (_rankings?.mostActive.take(3).map((s) => _buildTopLearnerItem(s, type: 'active')) ?? []).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopLearnerItem(StagiairePerformance s, {required String type}) {
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
            radius: 18,
            backgroundColor: Colors.white,
            backgroundImage: s.image != null && s.image!.isNotEmpty 
                ? NetworkImage(AppConstants.getUserImageUrl(s.image!)) : null,
            child: s.image == null ? Text(s.name.isNotEmpty ? s.name[0] : '?', style: const TextStyle(fontWeight: FontWeight.w900)) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: const TextStyle(color: FormateurTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 12)),
                Text(s.email, style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: FormateurTheme.border)),
            child: Text(
              type == 'quiz' ? '${s.totalQuizzes} quiz' : '${s.totalLogins} logs',
              style: TextStyle(
                color: type == 'quiz' ? FormateurTheme.accentDark : Colors.blue,
                fontWeight: FontWeight.w900,
                fontSize: 10
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _build3ColumnMiddleSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1024) {
          // Desktop: 3 columns
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: OnlineStagiairesCard(
                  stagiaires: _onlineStagiaires,
                  total: _onlineStagiaires.length,
                  onRefresh: _loadData,
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: FormationsViewCard(
                  formations: _paginatedFormations,
                  currentPage: _formationsPage,
                  lastPage: _formationsLastPage,
                  total: _formationsTotal,
                  onPageChanged: _onFormationsPageChanged,
                  onFormationTap: null, // TODO: Navigate to formations page when route is ready
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: FormateurViewCard(
                  formateurs: _paginatedFormateurs,
                  currentPage: _formateursPage,
                  lastPage: _formateursLastPage,
                  total: _formateursTotal,
                  onPageChanged: _onFormateursPageChanged,
                  onFormateurTap: null, // TODO: Navigate to arena page when route is ready
                ),
              ),
            ],
          );
        } else {
          // Mobile/Tablet: Stack vertically
          return Column(
            children: [
              OnlineStagiairesCard(
                stagiaires: _onlineStagiaires,
                total: _onlineStagiaires.length,
                onRefresh: _loadData,
              ),
              const SizedBox(height: 32),
              FormationsViewCard(
                formations: _paginatedFormations,
                currentPage: _formationsPage,
                lastPage: _formationsLastPage,
                total: _formationsTotal,
                onPageChanged: _onFormationsPageChanged,
                onFormationTap: null, // TODO: Navigate to formations page when route is ready
              ),
              const SizedBox(height: 32),
              FormateurViewCard(
                formateurs: _paginatedFormateurs,
                currentPage: _formateursPage,
                lastPage: _formateursLastPage,
                total: _formateursTotal,
                onPageChanged: _onFormateursPageChanged,
                onFormateurTap: null, // TODO: Navigate to arena page when route is ready
              ),
            ],
          );
        }
      },
    );
  }
  
  Widget _buildPerformanceSection() {
    if (_rankings == null) return const SizedBox.shrink();

    return Container(
      decoration: FormateurTheme.premiumCardDecoration,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: FormateurTheme.textPrimary, letterSpacing: -1.0),
              children: [
                TextSpan(text: 'Performance & '),
                TextSpan(text: 'Engagement', style: TextStyle(color: FormateurTheme.accent)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Corrélation entre temps de connexion et réussite aux examens.',
            style: TextStyle(color: FormateurTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 32),
          
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 900;
              if (isMobile) {
                return Column(
                  children: [
                    _buildRankingCard(
                      title: 'Top Quizzers',
                      subtitle: 'Champions de la révision',
                      icon: Icons.emoji_events_rounded,
                      color: FormateurTheme.accentDark,
                      data: _rankings!.mostQuizzes,
                      valueKey: 'quiz',
                    ),
                    const SizedBox(height: 24),
                    _buildRankingCard(
                      title: 'Top Actifs',
                      subtitle: 'Assiduité exemplaire',
                      icon: Icons.mouse_rounded,
                      color: Colors.blue,
                      data: _rankings!.mostActive,
                      valueKey: 'login',
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildRankingCard(
                      title: 'Top Quizzers',
                      subtitle: 'Champions de la révision',
                      icon: Icons.emoji_events_rounded,
                      color: FormateurTheme.accentDark,
                      data: _rankings!.mostQuizzes,
                      valueKey: 'quiz',
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: _buildRankingCard(
                      title: 'Top Actifs',
                      subtitle: 'Assiduité exemplaire',
                      icon: Icons.mouse_rounded,
                      color: Colors.blue,
                      data: _rankings!.mostActive,
                      valueKey: 'login',
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Formation Performance Cards
          if (_summary?.formations.isNotEmpty ?? false)
             Padding(
               padding: const EdgeInsets.only(top: 32),
               child: _buildFormationPerformanceSection(),
             ),
        ],
      ),
    );
  }

  Widget _buildRankingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<StagiairePerformance> data,
    required String valueKey,
  }) {
    // Ranking Card Implementation
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FormateurTheme.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FormateurTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: FormateurTheme.textPrimary, letterSpacing: -0.5)),
                  const SizedBox(height: 2),
                  Text(subtitle.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: FormateurTheme.textTertiary, letterSpacing: 0.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.take(5).length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final student = data[index];
              Color rankBgColor;
              Color rankTextColor;
              
              if (index == 0) {
                rankBgColor = color;
                rankTextColor = Colors.white;
              } else if (index == 1) {
                rankBgColor = Colors.grey.shade200;
                rankTextColor = Colors.grey.shade600;
              } else if (index == 2) {
                rankBgColor = Colors.orange.shade50;
                rankTextColor = Colors.orange.shade800;
              } else {
                rankBgColor = Colors.white;
                rankTextColor = FormateurTheme.textTertiary;
              }

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.transparent),
                  boxShadow: index == 0 ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))] : [],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: rankBgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: index > 2 ? Border.all(color: FormateurTheme.border) : null,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: rankTextColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: FormateurTheme.textPrimary)),
                          Text(student.email, style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 9, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          valueKey == 'quiz' ? '${student.totalQuizzes}' : '${student.totalLogins}', 
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color)
                        ),
                        Text(
                          valueKey == 'quiz' ? 'QUIZ' : 'LOGS', 
                          style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 8, fontWeight: FontWeight.w900)
                        ),
                      ],
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

