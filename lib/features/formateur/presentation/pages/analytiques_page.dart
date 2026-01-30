import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/analytics_model.dart';
import 'package:wizi_learn/features/formateur/data/models/formation_management_model.dart';
import 'package:wizi_learn/features/formateur/data/repositories/analytics_repository.dart';
import 'package:wizi_learn/features/formateur/data/repositories/formation_management_repository.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';

class AnalytiquesPage extends StatefulWidget {
  const AnalytiquesPage({super.key});

  @override
  State<AnalytiquesPage> createState() => _AnalytiquesPageState();
}

class _AnalytiquesPageState extends State<AnalytiquesPage> with SingleTickerProviderStateMixin {
  late final AnalyticsRepository _repository;
  late final FormationManagementRepository _formationRepository;
  late final TabController _tabController;

  int _selectedPeriod = 30;
  String? _selectedFormationId;
  bool _isLoading = true;

  DashboardSummary? _summary;
  List<FormationWithStats> _formations = [];
  List<QuizSuccessStats> _quizSuccessStats = [];
  List<ActivityByDay> _activityByDay = [];
  List<DropoutStats> _dropoutStats = [];
  List<dynamic> _formationsPerformance = [];
  List<dynamic> _studentsPerformance = [];
  List<dynamic> _mostQuizzes = [];
  List<dynamic> _mostActive = [];
  List<dynamic> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _repository = AnalyticsRepository(apiClient: apiClient);
    _formationRepository = FormationManagementRepository(apiClient: apiClient);
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (_formations.isEmpty) {
        _formations = await _formationRepository.getAvailableFormations();
      }

      final summary = await _repository.getDashboardSummary(
        period: _selectedPeriod,
        formationId: _selectedFormationId,
      );
      final success = await _repository.getQuizSuccessRate(
        period: _selectedPeriod,
        formationId: _selectedFormationId,
      );
      final activity = await _repository.getActivityByDay(
        period: _selectedPeriod,
        formationId: _selectedFormationId,
      );
      final dropout = await _repository.getDropoutStats(
        formationId: _selectedFormationId,
      );

      // Parity with React: Fetching extra analytics
      final performance = await _repository.getFormationsPerformance();
      final comparisonData = await _repository.getStudentsComparison(
        formationId: _selectedFormationId,
      );
      final activityLog = await _repository.getRecentActivity();

      setState(() {
        _summary = summary;
        _quizSuccessStats = success;
        _activityByDay = activity;
        _dropoutStats = dropout;
        _formationsPerformance = performance;
        _studentsPerformance = List<Map<String, dynamic>>.from(comparisonData['performance'] ?? []);
        final rankings = comparisonData['rankings'] ?? {};
        _mostQuizzes = List<Map<String, dynamic>>.from(rankings['most_quizzes'] ?? []);
        _mostActive = List<Map<String, dynamic>>.from(rankings['most_active'] ?? []);
        _recentActivity = activityLog;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: FormateurTheme.error),
        );
      }
    }
  }

  void _changePeriod(int days) {
    setState(() => _selectedPeriod = days);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormateurTheme.background,
      appBar: AppBar(
            title: const Text('Analytiques'), // Shortened for cleaner look
        backgroundColor: Colors.transparent,
        foregroundColor: FormateurTheme.textPrimary,
        elevation: 0,
        centerTitle: false,
        leading: Navigator.canPop(context) 
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
         titleTextStyle: const TextStyle(
            color: FormateurTheme.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            fontFamily: 'Montserrat'
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: FormateurTheme.accent,
          labelColor: FormateurTheme.accent,
          unselectedLabelColor: FormateurTheme.textTertiary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          tabs: const [
            Tab(text: 'Vue d\'ensemble'),
            Tab(text: 'Formations'),
            Tab(text: 'Taux réussite'),
            Tab(text: 'Activité'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FormateurTheme.accent))
          : Column(
              children: [
                // Formation Filter
                if (_formations.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: FormateurTheme.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedFormationId,
                          isExpanded: true,
                          hint: const Text('Toutes les formations', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: FormateurTheme.textSecondary),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Toutes les formations', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                            ..._formations.map((f) => DropdownMenuItem<String?>(
                                  value: f.id.toString(),
                                  child: Text(f.titre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedFormationId = value);
                            _loadData();
                          },
                        ),
                      ),
                    ),
                  ),

                // Period Selector
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: FormateurTheme.border),
                    ),
                    child: Row(
                      children: [
                        _PeriodChip('30J', 30, _selectedPeriod, _changePeriod),
                        _PeriodChip('60J', 60, _selectedPeriod, _changePeriod),
                        _PeriodChip('90J', 90, _selectedPeriod, _changePeriod),
                      ],
                    ),
                  ),
                ),
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildFormationsTab(),
                      _buildSuccessRateTab(),
                      _buildActiviteTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_summary == null) return const Center(child: Text('Pas de données'));

    return RefreshIndicator(
      onRefresh: _loadData,
      color: FormateurTheme.accent,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Summary Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _SummaryCard('Stagiaires', _summary!.totalStagiaires.toString(), Icons.people_rounded, const Color(0xFF3B82F6)),
              _SummaryCard('Actifs', _summary!.activeThisWeek.toString(), Icons.bolt_rounded, const Color(0xFF10B981)),
              _SummaryCard('Quiz Complétés', _summary!.totalQuizzesTaken.toString(), Icons.check_circle_rounded, const Color(0xFFF59E0B)),
              _SummaryCard('Score Moyen', '${_summary!.avgQuizScore.toStringAsFixed(1)}%', Icons.stars_rounded, const Color(0xFF8B5CF6)),
            ],
          ),
          const SizedBox(height: 24),

          // Trend Card (Premium Parity with React)
          _buildTrendCard(),
          const SizedBox(height: 32),

          // Top Formations Section
          if (_summary!.formations.isNotEmpty) ...[
            const Text(
              'Top Formations',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 0.5),
            ),
            const SizedBox(height: 16),
            ..._summary!.formations.take(5).map((f) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: FormateurTheme.border),
                    boxShadow: FormateurTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: FormateurTheme.accent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.school_rounded, color: FormateurTheme.accent, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.titre,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FormateurTheme.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${f.studentCount} apprenants',
                              style: const TextStyle(fontSize: 11, color: FormateurTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: FormateurTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${f.avgScore.toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: FormateurTheme.success),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          
          const SizedBox(height: 32),
          
          if (_studentsPerformance.isNotEmpty) ...[
            _buildComparisonSection(),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comparaison des Stagiaires',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: FormateurTheme.cardShadow,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              dataTableTheme: DataTableThemeData(
                headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                dataRowColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) return const Color(0xFFF1F5F9);
                  return Colors.white;
                }),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                horizontalMargin: 24,
                headingRowHeight: 48,
                dataRowMinHeight: 60,
                dataRowMaxHeight: 60,
                border: TableBorder(
                  bottom: BorderSide(color: const Color(0xFFE2E8F0).withOpacity(0.5)),
                  horizontalInside: BorderSide(color: const Color(0xFFE2E8F0).withOpacity(0.5)),
                ),
                headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B), fontSize: 11, letterSpacing: 0.5),
                columns: const [
                  DataColumn(label: Text('Stagiaire')),
                  DataColumn(label: Text('Points', textAlign: TextAlign.center)),
                  DataColumn(label: Text('Complétions', textAlign: TextAlign.center)),
                  DataColumn(label: Text('Score Moy.', textAlign: TextAlign.center)),
                ],
                rows: _studentsPerformance.map((s) => DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: FormateurTheme.accent.withOpacity(0.1),
                            child: Text(
                              (s['name'] ?? 'S')[0],
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FormateurTheme.accent),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            s['name'] ?? 'Inconnu',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: FormateurTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Center(child: Text('${s['total_points'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                    DataCell(Center(child: Text('${s['total_completions'] ?? 0}', style: const TextStyle(fontSize: 12)))),
                    DataCell(
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getScoreColor((s['average_score'] ?? 0).toDouble()).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(s['average_score'] ?? 0).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: _getScoreColor((s['average_score'] ?? 0).toDouble()),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessRateTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: FormateurTheme.accent,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Performance Quiz',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 20),
          if (_quizSuccessStats.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('Aucune donnée de quiz disponible', style: TextStyle(color: FormateurTheme.textTertiary)),
            ))
          else
            ..._quizSuccessStats.map((stat) => Container(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stat.quizName,
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: FormateurTheme.textPrimary, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(stat.category, style: const TextStyle(fontSize: 11, color: FormateurTheme.textSecondary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getScoreColor(stat.successRate).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${stat.successRate.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: _getScoreColor(stat.successRate),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: stat.successRate / 100,
                          minHeight: 8,
                          backgroundColor: FormateurTheme.background,
                          valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(stat.successRate)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${stat.successfulAttempts} réussites sur ${stat.totalAttempts} essais',
                        style: const TextStyle(fontSize: 11, color: FormateurTheme.textTertiary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildActiviteTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: FormateurTheme.accent,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildActivityHeatmap(),
          const SizedBox(height: 24),
          _buildRecentActivityFeed(),
          const SizedBox(height: 24),
          _buildDropoutStats(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildActivityHeatmap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activité Quotidienne',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 0.5),
        ),
        const SizedBox(height: 20),
        Container(
          height: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: FormateurTheme.border),
            boxShadow: FormateurTheme.cardShadow,
          ),
          child: _activityByDay.isEmpty
              ? const Center(child: Text("Pas d'activité récente"))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (_activityByDay.isEmpty ? 10 : _activityByDay.map((e) => e.activityCount).reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => FormateurTheme.accentDark,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            rod.toY.round().toString(),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            if (value.toInt() >= 0 && value.toInt() < _activityByDay.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _activityByDay[value.toInt()].day,
                                  style: const TextStyle(
                                    color: FormateurTheme.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 5,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: FormateurTheme.border,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _activityByDay.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.activityCount.toDouble(),
                            color: FormateurTheme.accent,
                            width: 12,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: (_activityByDay.isEmpty ? 10 : _activityByDay.map((e) => e.activityCount).reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
                              color: FormateurTheme.background,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDropoutStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Taux d\'abandon',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 0.5),
        ),
        const SizedBox(height: 20),
        ..._dropoutStats.take(5).map((dropout) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FormateurTheme.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(
                    dropout.quizName, 
                    style: const TextStyle(color: FormateurTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)
                ),
                subtitle: Text(
                    '${dropout.abandoned} abandons', 
                    style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 11)
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (dropout.dropoutRate > 50 ? FormateurTheme.error : FormateurTheme.orangeAccent).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${dropout.dropoutRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: dropout.dropoutRate > 50 ? FormateurTheme.error : FormateurTheme.accent,
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildRecentActivityFeed() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: FormateurTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history, size: 16, color: FormateurTheme.accent),
              ),
              const SizedBox(width: 12),
              const Text(
                'ACTIVITÉS RÉCENTES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_recentActivity.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('Aucune activité récente'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentActivity.length,
              separatorBuilder: (context, index) => Divider(color: Colors.grey.shade50, height: 24),
              itemBuilder: (context, index) {
                final activity = _recentActivity[index];
                final user = activity['user'] ?? {};
                final content = activity['content'] ?? {};
                
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: user['image'] != null && user['image'].isNotEmpty 
                        ? NetworkImage(AppConstants.getUserImageUrl(user['image'])) 
                        : null,
                      child: user['image'] == null || user['image'].isEmpty
                        ? Text(
                            '${(user['prenom'] ?? user['name'] ?? '?')[0].toUpperCase()}${(user['name'] ?? '')[0].toUpperCase()}', 
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
                          )
                        : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${user['prenom'] ?? ''} ${(user['nom'] ?? user['name'] ?? 'Inconnu').toString().toUpperCase()}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              if (activity['created_at'] != null)
                                Text(
                                  DateFormat('dd/MM HH:mm').format(DateTime.parse(activity['created_at'].toString())),
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.4),
                              children: [
                                const TextSpan(text: 'A terminé le quiz '),
                                TextSpan(
                                  text: content['quiz_title'] ?? 'Inconnu',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: FormateurTheme.accent),
                                ),
                                const TextSpan(text: ' avec un score de '),
                                TextSpan(
                                  text: '${(content['score'] ?? 0) * 10}%',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTrendCard() {
    if (_summary == null) return const SizedBox.shrink();
    
    // Calculated trend for parity with React
    final double trendVal = 12.5; 
    final bool isUp = trendVal >= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tendance',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                '${isUp ? '+' : ''}$trendVal%',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  letterSpacing: -1,
                ),
              ),
              const Text(
                'Par rapport à la période précédente',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormationsTab() {
    if (_formationsPerformance.isEmpty) {
      return const Center(child: Text('Aucune donnée de performance de formation'));
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Performance des Formations',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5),
        ),
        const SizedBox(height: 20),
        Container(
          height: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: FormateurTheme.cardShadow,
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceEvenly,
              maxY: 100,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => FormateurTheme.accentDark,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final formationName = groupIndex < _formationsPerformance.length
                        ? (_formationsPerformance[groupIndex]['nom'] ?? '')
                        : '';
                    final metric = rodIndex == 0 ? 'Complétion' : 'Score';
                    return BarTooltipItem(
                      '$formationName\n$metric: ${rod.toY.round()}%',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() >= 0 && value.toInt() < _formationsPerformance.length) {
                        final name = _formationsPerformance[value.toInt()]['nom'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            name.length > 10 ? '${name.substring(0, 8)}...' : name,
                            style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: FormateurTheme.border,
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: _formationsPerformance.asMap().entries.map((entry) {
                final f = entry.value;
                return BarChartGroupData(
                  x: entry.key,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                      toY: (f['completion_rate'] ?? 0).toDouble(),
                      color: const Color(0xFFF7931E),
                      width: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    BarChartRodData(
                      toY: (f['average_score'] ?? 0).toDouble(),
                      color: const Color(0xFFFACC15),
                      width: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFFF7931E), borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 8),
              const Text('Taux Complétion', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            ]),
            const SizedBox(width: 24),
            Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFFFACC15), borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 8),
              const Text('Score Moyen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            ]),
          ],
        ),
        const SizedBox(height: 32),
        // Rankings Section (New for React parity)
        if (_mostQuizzes.isNotEmpty || _mostActive.isNotEmpty) ...[
          _buildRankingsSection(),
          const SizedBox(height: 24),
        ],
        _buildStudentsTable(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildStudentsTable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STAGIAIRES DE CETTE FORMATION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          if (_studentsPerformance.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('Aucun stagiaire trouvé'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _studentsPerformance.length,
              separatorBuilder: (context, index) => Divider(color: Colors.grey.shade50),
              itemBuilder: (context, index) {
                final student = _studentsPerformance[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    backgroundImage: student['image'] != null && student['image'].isNotEmpty 
                      ? NetworkImage(AppConstants.getUserImageUrl(student['image'])) 
                      : null,
                    child: student['image'] == null || student['image'].isEmpty
                      ? Text(
                          '${(student['prenom'] ?? student['name'] ?? 'S')[0].toUpperCase()}${(student['name'] ?? student['nom'] ?? '')[0].toUpperCase()}', 
                          style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 10)
                        )
                      : null,
                  ),
                  title: Text(
                    '${student['prenom'] ?? ''} ${(student['nom'] ?? student['name'] ?? '').toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    '${student['total_quizzes']} quiz • Score moy. ${student['avg_score']}%',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 16),
                  onTap: () {
                    // Logic to view student details
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRankingsSection() {
    return Column(
      children: [
        if (_mostQuizzes.isNotEmpty) ...[
          _buildRankingList('Champions des Quiz', _mostQuizzes, Icons.emoji_events_rounded, Colors.orange),
          const SizedBox(height: 24),
        ],
        if (_mostActive.isNotEmpty) ...[
          _buildRankingList('Les plus Actifs', _mostActive, Icons.bolt_rounded, Colors.blue),
        ],
      ],
    );
  }

  Widget _buildRankingList(String title, List<dynamic> students, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: FormateurTheme.textPrimary, letterSpacing: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...students.take(3).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final s = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FormateurTheme.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withOpacity(0.1),
                  child: Text('${index + 1}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${s['prenom'] ?? ''} ${(s['nom'] ?? s['name'] ?? 'Inconnu').toString().toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Text(
                  title.contains('Quiz') ? '${s['total_quizzes'] ?? 0} quiz' : '${s['total_logins'] ?? 0} logs',
                  style: TextStyle(color: FormateurTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 70) return FormateurTheme.success;
    if (score >= 50) return FormateurTheme.accent;
    return FormateurTheme.error;
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final int days;
  final int selectedPeriod;
  final Function(int) onTap;

  const _PeriodChip(this.label, this.days, this.selectedPeriod, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isSelected = days == selectedPeriod;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap(days);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? FormateurTheme.textPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : FormateurTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FormateurTheme.border),
        boxShadow: FormateurTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1)),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value, 
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.w900, 
              color: FormateurTheme.textPrimary, 
              letterSpacing: -1
            )
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10, 
              color: FormateurTheme.textSecondary, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 0.5
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
