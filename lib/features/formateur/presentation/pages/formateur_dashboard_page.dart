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
                          // Critical Alerts
                          if (_inactiveStagiaires.isNotEmpty) ...[
                            _buildCriticalAlertsSection(),
                            const SizedBox(height: 24),
                          ],

                          // Stats Grid
                          if (_summary != null) ...[
                            _buildStatsGrid(),
                            const SizedBox(height: 24),
                          ],

                          // Quick Actions
                          _buildQuickActions(),
                          const SizedBox(height: 32),

                          // Sections Header
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: FormateurTheme.accent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'ACTIVITÉ EN DIRECT',
                                style: TextStyle(
                                  color: FormateurTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Search and Filters
                          _buildSearchAndFilters(),
                          const SizedBox(height: 24),

                          // Online Stagiaires Section
                          _buildOnlineStagiairesSection(),
                          const SizedBox(height: 32),

                          // Formation Selector
                          if (_formations.isNotEmpty) ...[
                            _buildFormationSelector(),
                          ],
                        ],
                      ),
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
                      'ESPACE FORMATEUR',
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
                    TextSpan(text: 'Dashboard\n'),
                    TextSpan(
                      text: 'Analytique',
                      style: TextStyle(color: FormateurTheme.accentDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Supervisez l'engagement et l'excellence académique de vos cohortes.",
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
                    'ATTENTION',
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
                    child: const Text('VOIR PROFIL'),
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
        _buildStatCard('Stagiaires', _summary?.totalStagiaires.toString() ?? '0', Icons.people_alt_rounded, Colors.blue),
        _buildStatCard('Programmes', _summary?.activeThisWeek.toString() ?? '0', Icons.auto_awesome_motion_rounded, Colors.purple),
        _buildStatCard('Score Moyen', '${_summary?.avgQuizScore ?? 0}%', Icons.military_tech_rounded, FormateurTheme.accentDark),
        _buildStatCard('Inactifs', _summary?.inactiveCount.toString() ?? '0', Icons.notifications_active_rounded, FormateurTheme.orangeAccent),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: FormateurTheme.premiumCardDecoration,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: FormateurTheme.textPrimary, letterSpacing: -1),
              ),
              const SizedBox(height: 2),
              Text(
                title.toUpperCase(),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      decoration: FormateurTheme.premiumCardDecoration.copyWith(
        color: FormateurTheme.textPrimary,
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(Icons.emoji_events_rounded, 'COHORTES', () => Navigator.pushNamed(context, '/formateur/classement')),
          Container(width: 1, height: 30, color: Colors.white10),
          _buildActionButton(Icons.campaign_rounded, 'NOTIFIER', () => Navigator.pushNamed(context, '/formateur/send-notification')),
          Container(width: 1, height: 30, color: Colors.white10),
          _buildActionButton(Icons.insert_chart_rounded, 'STATS', () => Navigator.pushNamed(context, '/formateur/analytiques')),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Column(
        children: [
          Icon(icon, color: FormateurTheme.accent, size: 24),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FormateurTheme.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Rechercher un apprenant...',
          hintStyle: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 13, fontWeight: FontWeight.w700),
          prefixIcon: const Icon(Icons.search, color: FormateurTheme.accent, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
        style: const TextStyle(color: FormateurTheme.textPrimary, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildOnlineStagiairesSection() {
    if (_onlineStagiaires.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _onlineStagiaires.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final stagiaire = _onlineStagiaires[index];
            return Container(
              decoration: FormateurTheme.premiumCardDecoration,
              child: ListTile(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => StagiaireProfilePage(stagiaireId: stagiaire.id)));
                },
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: FormateurTheme.success, width: 2)),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: FormateurTheme.background,
                    backgroundImage: stagiaire.avatar != null && stagiaire.avatar!.isNotEmpty
                      ? NetworkImage(AppConstants.getUserImageUrl(stagiaire.avatar!)) : null,
                    child: (stagiaire.avatar == null || stagiaire.avatar!.isEmpty) ? Text(stagiaire.prenom[0], style: const TextStyle(fontWeight: FontWeight.w900)) : null,
                  ),
                ),
                title: Text('${stagiaire.prenom} ${stagiaire.nom}'.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: -0.5)),
                subtitle: const Row(
                  children: [
                    Icon(Icons.circle, color: FormateurTheme.success, size: 8),
                    SizedBox(width: 6),
                    Text('EN LIGNE', style: TextStyle(color: FormateurTheme.success, fontSize: 10, fontWeight: FontWeight.w900)),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: FormateurTheme.border),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFormationSelector() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: FormateurTheme.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FILTRER PAR FORMATION', style: TextStyle(color: FormateurTheme.textTertiary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          const SizedBox(height: 16),
          DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedFormationId,
              isExpanded: true,
              hint: const Text('Toutes les formations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
              icon: const Icon(Icons.expand_more_rounded, color: FormateurTheme.accent),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Toutes les formations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900))),
                ..._formations.map((f) => DropdownMenuItem<String?>(value: f.id.toString(), child: Text(f.titre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)))),
              ],
              onChanged: (value) {
                setState(() => _selectedFormationId = value);
                _loadData();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopLearnersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOP PERFORMANCE',
              style: TextStyle(color: FormateurTheme.textTertiary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: FormateurTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Text('30 JOURS', style: TextStyle(color: FormateurTheme.accentDark, fontSize: 9, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: FormateurTheme.premiumCardDecoration,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: FormateurTheme.orangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.star_rounded, color: FormateurTheme.orangeAccent, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Text('Leaders de Quiz', style: TextStyle(color: FormateurTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ],
              ),
              const SizedBox(height: 24),
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
            radius: 18,
            backgroundColor: Colors.white,
            backgroundImage: s.image != null && s.image!.isNotEmpty 
                ? NetworkImage(AppConstants.getUserImageUrl(s.image!)) : null,
            child: s.image == null ? Text(s.name[0], style: const TextStyle(fontWeight: FontWeight.w900)) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name.toUpperCase(), style: const TextStyle(color: FormateurTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 12)),
                Text('${s.totalQuizzes} quiz complétés', style: const TextStyle(color: FormateurTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: FormateurTheme.border)),
            child: Text('${s.totalLogins} connexions', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
