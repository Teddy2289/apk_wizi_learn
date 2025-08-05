import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/progress_stats.dart';
import 'package:wizi_learn/features/auth/data/repositories/progression_repository.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  _ProgressPageState createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  late ProgressRepository _repository;
  ProgressStats? _progressStats;
  bool _isLoading = true;
  String _error = '';
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _repository = ProgressRepository(apiClient: apiClient);
    _loadProgressData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= 400 && !_showBackToTopButton) {
      setState(() => _showBackToTopButton = true);
    } else if (_scrollController.offset < 400 && _showBackToTopButton) {
      setState(() => _showBackToTopButton = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadProgressData() async {
    try {
      final progressStats = await _repository.getProgressStats();
      setState(() {
        _progressStats = progressStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Échec du chargement des données de progression';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma Progression'),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed:
              () => Navigator.pushReplacementNamed(
            context,
            RouteConstants.dashboard,
          ),
        ),
        backgroundColor: isDarkMode ? theme.appBarTheme.backgroundColor : Colors.white,
        elevation: 1,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      ),
      body: _buildBody(theme),
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
        onPressed: _scrollToTop,
        mini: true,
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.arrow_upward, color: theme.colorScheme.onPrimary),
      )
          : null,
    );
  }

  Widget _buildBody(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadProgressData,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Votre progression',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Retrouvez ici votre activité quotidienne, hebdomadaire et mensuelle',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (_isLoading)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                ),
              )
            else if (_error.isNotEmpty)
              SliverFillRemaining(
                child: _buildErrorState(theme),
              )
            else if (_progressStats == null)
                SliverFillRemaining(
                  child: _buildEmptyState(theme),
                )
              else
                SliverList(
                  delegate: SliverChildListDelegate([
                    _buildProgressSection(
                      title: 'Progression Quotidienne',
                      icon: Icons.calendar_today,
                      color: Colors.blue,
                      progressList: _progressStats!.dailyProgress,
                      isDaily: true,
                      theme: theme,
                    ),
                    const SizedBox(height: 24),
                    _buildProgressSection(
                      title: 'Progression Hebdomadaire',
                      icon: Icons.date_range,
                      color: Colors.green,
                      progressList: _progressStats!.weeklyProgress,
                      isDaily: false,
                      theme: theme,
                    ),
                    const SizedBox(height: 24),
                    _buildProgressSection(
                      title: 'Progression Mensuelle',
                      icon: Icons.calendar_month,
                      color: Colors.purple,
                      progressList: _progressStats!.monthlyProgress,
                      isDaily: false,
                      theme: theme,
                    ),
                    const SizedBox(height: 80),
                  ]),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<dynamic> progressList,
    required bool isDaily,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (progressList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Aucune donnée disponible',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          )
        else
          ...progressList.map((progress) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          isDaily
                              ? progress.date.split('-').last
                              : progress is WeeklyProgress
                              ? progress.week.split('-').last
                              : progress.month.split('-').last,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDaily
                                ? _formatDate(progress.date)
                                : progress is WeeklyProgress
                                ? 'Semaine ${progress.week.split('-').last}'
                                : _formatMonth(progress.month),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quiz complétés: ${progress.completedQuizzes}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Moy: ${progress.averagePoints.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return date;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  String _formatMonth(String month) {
    final parts = month.split('-');
    if (parts.length != 2) return month;
    final months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    final monthIndex = int.tryParse(parts[1]) ?? 1;
    return '${months[monthIndex - 1]} ${parts[0]}';
  }

  Widget _buildErrorState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Erreur de chargement',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _error,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loadProgressData,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: const Text('Réessayer'),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.insights,
          size: 48,
          color: theme.colorScheme.primary.withOpacity(0.5),
        ),
        const SizedBox(height: 16),
        Text(
          'Aucune donnée de progression',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Vos données de progression apparaîtront ici une fois que vous aurez complété des quiz.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}