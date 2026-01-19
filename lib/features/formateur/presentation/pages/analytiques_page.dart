import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: const Text('Analytiques & Rapports'),
        backgroundColor: const Color(0xFFF7931E),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Vue d\'ensemble'),
            Tab(icon: Icon(Icons.quiz), text: 'Taux de réussite'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Activité'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Period Selector
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('Période:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      _PeriodChip('30j', 30, _selectedPeriod, _changePeriod),
                      _PeriodChip('60j', 60, _selectedPeriod, _changePeriod),
                      _PeriodChip('90j', 90, _selectedPeriod, _changePeriod),
                    ],
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(child: _SummaryCard('Total Stagiaires', _summary!.totalStagiaires.toString(), Icons.people, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _SummaryCard('Actifs', _summary!.activeStagiaires.toString(), Icons.person, Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _SummaryCard('Complétés', _summary!.totalCompletions.toString(), Icons.check_circle, Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _SummaryCard('Score Moyen', '${_summary!.averageScore.toStringAsFixed(1)}%', Icons.star, Colors.amber)),
            ],
          ),
          const SizedBox(height: 16),

          // Trend
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _summary!.trendPercentage >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: _summary!.trendPercentage >= 0 ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tendance', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        '${_summary!.trendPercentage >= 0 ? '+' : ''}${_summary!.trendPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _summary!.trendPercentage >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        'vs période précédente',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessRateTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('TAUX DE RÉUSSITE PAR QUIZ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          ..._successStats.map((stat) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stat.quizName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(stat.category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: stat.successRate / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          stat.successRate >= 70 ? Colors.green : stat.successRate >= 50 ? Colors.orange : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${stat.successRate.toStringAsFixed(1)}% réussite', style: const TextStyle(fontSize: 12)),
                          Text('${stat.successfulAttempts}/${stat.totalAttempts} tentatives', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('ACTIVITÉ PAR JOUR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          ..._activityByDay.map((day) {
            final maxCount = _activityByDay.isEmpty ? 1 : _activityByDay.map((d) => d.activityCount).reduce((a, b) => a > b ? a : b);
            final barWidth = day.activityCount / maxCount;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(day.day, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: barWidth,
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF7931E), Color(0xFFFFB84D)],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${day.activityCount}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          const Text('TAUX D\'ABANDON', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          ..._dropoutStats.take(5).map((dropout) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(dropout.quizName),
                  subtitle: Text('${dropout.abandoned}/${dropout.totalAttempts} abandonnés'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: dropout.dropoutRate > 50 ? Colors.red[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${dropout.dropoutRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
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
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTap(days),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF7931E) : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 12),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
