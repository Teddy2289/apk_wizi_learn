import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/analytics_model.dart';
import 'package:wizi_learn/features/formateur/data/models/formation_management_model.dart';
import 'package:wizi_learn/features/formateur/data/repositories/analytics_repository.dart';
import 'package:wizi_learn/features/formateur/data/repositories/formation_management_repository.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';

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
  bool _loading = true;

  DashboardSummary? _summary;
  List<FormationWithStats> _formations = [];
  List<QuizSuccessStats> _successStats = [];
  List<ActivityByDay> _activityByDay = [];
  List<DropoutStats> _dropoutStats = [];

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _repository = AnalyticsRepository(apiClient: apiClient);
    _formationRepository = FormationManagementRepository(apiClient: apiClient);
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
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

      setState(() {
        _summary = summary;
        _successStats = success;
        _activityByDay = activity;
        _dropoutStats = dropout;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
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
            Tab(text: 'GÉNÉRAL'),
            Tab(text: 'SUCCÈS'),
            Tab(text: 'ACTIVITÉ'),
          ],
        ),
      ),
      body: _loading
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
                      _buildSuccessRateTab(),
                      _buildActivityTab(),
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
              _SummaryCard('Stagiaires', _summary!.totalStagiaires.toString(), Icons.people_outline, Colors.blue),
              _SummaryCard('Actifs (Semaine)', _summary!.activeThisWeek.toString(), Icons.person_add_alt_1_outlined, FormateurTheme.success),
              _SummaryCard('Quiz Passés', _summary!.totalQuizzesTaken.toString(), Icons.emoji_events_outlined, FormateurTheme.accent),
              _SummaryCard('Score Moy.', '${_summary!.avgQuizScore.toStringAsFixed(1)}%', Icons.analytics_outlined, FormateurTheme.accent),
            ],
          ),
          const SizedBox(height: 24),
          
          // Additional Stats Row
          const SizedBox(height: 32),

          // Top Formations Section
          if (_summary!.formations.isNotEmpty) ...[
            const Text(
              'TOP FORMATIONS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 1.5),
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
        ],
      ),
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
            'PERFORMANCE QUIZ',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 1.5),
          ),
          const SizedBox(height: 20),
          if (_successStats.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('Aucune donnée de quiz disponible', style: TextStyle(color: FormateurTheme.textTertiary)),
            ))
          else
            ..._successStats.map((stat) => Container(
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
                                  stat.quizName.toUpperCase(),
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

  Widget _buildActivityTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: FormateurTheme.accent,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'ACTIVITÉ QUOTIDIENNE',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 1.5),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: FormateurTheme.border),
               boxShadow: FormateurTheme.cardShadow,
            ),
            child: Column(
              children: _activityByDay.map((day) {
                final maxCount = _activityByDay.isEmpty ? 1 : _activityByDay.map((d) => d.activityCount).reduce((a, b) => a > b ? a : b);
                final barWidth = maxCount > 0 ? day.activityCount / maxCount : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(day.day, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FormateurTheme.textTertiary)),
                      ),
                      Expanded(
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: FormateurTheme.background,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: barWidth > 0 ? barWidth : 0.02,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [FormateurTheme.accent, FormateurTheme.accentDark],
                                ),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(color: FormateurTheme.accent.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                                ]
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${day.activityCount}',
                        style: const TextStyle(color: FormateurTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'TAUX D\'ABANDON',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 1.5),
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
      ),
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
