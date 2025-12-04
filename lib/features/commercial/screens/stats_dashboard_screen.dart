import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/commercial_colors.dart';
import '../models/stats_data.dart';
import '../services/commercial_service.dart';
import '../widgets/stat_card.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';

class StatsDashboardScreen extends StatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  String _selectedRange = '7d';
  String _selectedMetric = 'signups';
  bool _isLoading = false;
  StatsData? _statsData;

  late CommercialService _commercialService;

  final Map<String, String> _rangeLabels = {
    '7d': '7 derniers jours',
    '30d': '30 derniers jours',
    '90d': '90 derniers jours',
    '1y': '1 an',
  };

  final Map<String, String> _metricLabels = {
    'signups': 'Inscriptions',
    'activeSessions': 'Sessions actives',
    'revenue': 'Revenu',
    'completedCourses': 'Formations complétées',
  };

  @override
  void initState() {
    super.initState();
    final dio = Dio();
    _commercialService = CommercialService(dio, baseUrl: AppConstants.baseUrl);
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _commercialService.getStats(
        range: _selectedRange,
        metric: _selectedMetric,
      );
      setState(() => _statsData = stats);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _statsData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: CommercialColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Filters card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: CommercialColors.borderOrange),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 18, color: CommercialColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedRange,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            items: _rangeLabels.entries.map((entry) {
                              return DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedRange = value!);
                              _loadStats();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedMetric,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      items: _metricLabels.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedMetric = value!);
                        _loadStats();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Stat cards grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  title: 'Inscriptions',
                  value: _statsData?.signups.toString() ?? '0',
                  icon: LucideIcons.users,
                  gradient: CommercialColors.orangeGradient,
                ),
                StatCard(
                  title: 'Sessions actives',
                  value: _statsData?.activeSessions.toString() ?? '0',
                  icon: LucideIcons.activity,
                  gradient: CommercialColors.yellowGradient,
                ),
                StatCard(
                  title: 'Revenu (€)',
                  value: NumberFormat.compact().format(_statsData?.revenue ?? 0),
                  icon: LucideIcons.dollarSign,
                  gradient: CommercialColors.amberGradient,
                ),
                StatCard(
                  title: 'Formations',
                  value: _statsData?.completedCourses.toString() ?? '0',
                  icon: LucideIcons.trendingUp,
                  gradient: CommercialColors.orangeGradient,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Chart card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: CommercialColors.borderOrange),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Évolution dans le temps',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: _statsData != null && _statsData!.chartData.isNotEmpty
                          ? LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: CommercialColors.borderOrange.withOpacity(0.3),
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 && index < _statsData!.chartData.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              _statsData!.chartData[index].date,
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _statsData!.chartData
                                        .asMap()
                                        .entries
                                        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                                        .toList(),
                                    isCurved: true,
                                    gradient: CommercialColors.orangeGradient,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        colors: [
                                          CommercialColors.primaryOrange.withOpacity(0.1),
                                          CommercialColors.primaryOrange.withOpacity(0.0),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const Center(child: Text('Aucune donnée disponible')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
