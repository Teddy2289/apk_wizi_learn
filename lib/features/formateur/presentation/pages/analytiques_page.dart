import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/analytics_model.dart';
import 'package:wizi_learn/features/formateur/data/repositories/analytics_repository.dart';

class AnalytiquesPage extends StatefulWidget {
  const AnalytiquesPage({super.key});

  @override
  State<AnalytiquesPage> createState() => _AnalytiquesPageState();
}

class _AnalytiquesPageState extends State<AnalytiquesPage> with SingleTickerProviderStateMixin {
  late final AnalyticsRepository _repository;
  late final TabController _tabController;

  int _selectedPeriod = 30;
  bool _loading = true;

  DashboardSummary? _summary;
  List<QuizSuccessStats> _successStats = [];
  List<ActivityByDay> _activityByDay = [];
  List<DropoutStats> _dropoutStats = [];

  @override
  void initState() {
    super.initState();
    _repository = AnalyticsRepository(
      apiClient: ApiClient(
        dio: Dio(),
        storage: const FlutterSecureStorage(),
      ),
    );
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
      final summary = await _repository.getDashboardSummary(period: _selectedPeriod);
      final success = await _repository.getQuizSuccessRate(period: _selectedPeriod);
      final activity = await _repository.getActivityByDay(period: _selectedPeriod);
      final dropout = await _repository.getDropoutStats();

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
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
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
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Analytiques & Rapports'),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF7931E),
          labelColor: const Color(0xFFF7931E),
          unselectedLabelColor: Colors.white.withOpacity(0.5),
          tabs: const [
            Tab(text: 'OVERVIEW'),
            Tab(text: 'SUCCESS'),
            Tab(text: 'ACTIVITY'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF7931E)))
          : Column(
              children: [
                // Period Selector (Segmented Control style)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _PeriodChip('30D', 30, _selectedPeriod, _changePeriod),
                        _PeriodChip('60D', 60, _selectedPeriod, _changePeriod),
                        _PeriodChip('90D', 90, _selectedPeriod, _changePeriod),
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
    if (_summary == null) return const Center(child: Text('Pas de données', style: TextStyle(color: Colors.white54)));

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFF7931E),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _SummaryCard('Students', _summary!.totalStagiaires.toString(), Icons.people, const Color(0xFF00A8FF)),
              _SummaryCard('Active', _summary!.activeStagiaires.toString(), Icons.person_add, const Color(0xFF00D084)),
              _SummaryCard('Completes', _summary!.totalCompletions.toString(), Icons.star, const Color(0xFFF7931E)),
              _SummaryCard('Avg Score', '${_summary!.averageScore.toStringAsFixed(1)}%', Icons.analytics, const Color(0xFFFFA500)),
            ],
          ),
          const SizedBox(height: 16),

          // Trend Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_summary!.trendPercentage >= 0 ? Colors.green : Colors.red).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _summary!.trendPercentage >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: _summary!.trendPercentage >= 0 ? Colors.green : Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PERFORMANCE TREND',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.3), letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_summary!.trendPercentage >= 0 ? '+' : ''}${_summary!.trendPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _summary!.trendPercentage >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'vs prev.',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.2)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSuccessRateTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFF7931E),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'QUIZ PERFORMANCE',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.3), letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          if (_successStats.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('No quiz stats available', style: TextStyle(color: Colors.white24)),
            ))
          else
            ..._successStats.map((stat) => Container(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stat.quizName.toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(stat.category, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
                              ],
                            ),
                          ),
                          Text(
                            '${stat.successRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: stat.successRate >= 70 ? Colors.green : stat.successRate >= 50 ? Colors.orange : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: stat.successRate / 100,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            stat.successRate >= 70 ? Colors.green : stat.successRate >= 50 ? Colors.orange : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${stat.successfulAttempts} of ${stat.totalAttempts} attempts successful',
                        style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.bold),
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
      color: const Color(0xFFF7931E),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'DAILY ACTIVITY',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.3), letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: _activityByDay.map((day) {
                final maxCount = _activityByDay.isEmpty ? 1 : _activityByDay.map((d) => d.activityCount).reduce((a, b) => a > b ? a : b);
                final barWidth = day.activityCount / maxCount;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(day.day, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54)),
                      ),
                      Expanded(
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: barWidth > 0 ? barWidth : 0.02,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF7931E), Color(0xFFFFB84D)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${day.activityCount}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'DROPOUT BY QUIZ',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.3), letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          ..._dropoutStats.take(5).map((dropout) => Card(
                color: const Color(0xFF2A2A2A),
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(dropout.quizName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text('${dropout.abandoned} abandoned', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (dropout.dropoutRate > 50 ? Colors.red : Colors.orange).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${dropout.dropoutRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: dropout.dropoutRate > 50 ? Colors.red : Colors.orange,
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF7931E) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white60,
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
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.bold, letterSpacing: 0.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
