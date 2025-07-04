import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/stats_model.dart';

class QuizHistoryWidget extends StatefulWidget {
  final List<QuizHistory> history;

  const QuizHistoryWidget({super.key, required this.history});

  @override
  State<QuizHistoryWidget> createState() => _QuizHistoryWidgetState();
}

class _QuizHistoryWidgetState extends State<QuizHistoryWidget> {
  final int _itemsPerPage = 5;
  int _currentPage = 1;
  int get _totalPages => (widget.history.length / _itemsPerPage).ceil();

  List<QuizHistory> get _currentPageItems {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return widget.history.sublist(
      startIndex,
      endIndex > widget.history.length ? widget.history.length : endIndex,
    );
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);
    final totalQuizzes = widget.history.length;

    return Card(
      margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history_outlined,
                      color: theme.primaryColor,
                      size: isSmallScreen ? 24 : 28,
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Text(
                      'Historique des Quiz',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$totalQuizzes quiz complétés',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Page $_currentPage/$_totalPages',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Liste des quiz
          Flexible(
            child: _currentPageItems.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.only(
                left: isSmallScreen ? 16 : 20,
                right: isSmallScreen ? 16 : 20,
                bottom: 16,
              ),
              itemCount: _currentPageItems.length,
              separatorBuilder: (_, __) => SizedBox(height: isSmallScreen ? 12 : 16),
              itemBuilder: (_, index) => _buildHistoryItem(
                _currentPageItems[index],
                isSmallScreen,
              ),
            ),
          ),

          // Pagination
          if (widget.history.isNotEmpty) _buildPaginationControls(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 48,
            color: Colors.grey.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun quiz complété',
            style: TextStyle(
              color: Colors.grey.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(QuizHistory item, bool isSmallScreen) {
    final theme = Theme.of(context);
    final scorePercentage = (item.correctAnswers / item.totalQuestions) * 100;
    final dateTime = item.completedAt.split('T');
    final completedDate = dateTime[0];
    final completedTime = dateTime[1].substring(0, 5);

    return Material(
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.surface,
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre et score
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.quiz.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  _buildScoreIndicator(scorePercentage, isSmallScreen),
                ],
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),

              // Catégories
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildCategoryTag(
                    icon: Icons.category_outlined,
                    label: item.quiz.category,
                    color: Colors.blue,
                    isSmallScreen: isSmallScreen,
                  ),
                  _buildCategoryTag(
                    icon: Icons.star_outline,
                    label: item.quiz.level,
                    color: Colors.amber,
                    isSmallScreen: isSmallScreen,
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),

              // Détails
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailItem(
                    icon: Icons.score_outlined,
                    value: '${item.correctAnswers}/${item.totalQuestions}',
                    isSmallScreen: isSmallScreen,
                  ),
                  _buildDetailItem(
                    icon: Icons.timer_outlined,
                    value: '${item.timeSpent ~/ 60}m ${item.timeSpent % 60}s',
                    isSmallScreen: isSmallScreen,
                  ),
                  _buildDetailItem(
                    icon: Icons.calendar_today_outlined,
                    value: '$completedDate à $completedTime',
                    isSmallScreen: isSmallScreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(double percentage, bool isSmallScreen) {
    final color = _getScoreColor(percentage / 100);
    return Container(
      width: isSmallScreen ? 48 : 56,
      height: isSmallScreen ? 48 : 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '${percentage.toStringAsFixed(0)}%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 14 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTag({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      avatar: Icon(icon, size: isSmallScreen ? 16 : 18, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: isSmallScreen ? 12 : 13,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String value,
    required bool isSmallScreen,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: isSmallScreen ? 16 : 18,
          color: Colors.grey.withOpacity(0.6),
        ),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            color: Colors.grey.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_currentPageItems.length} éléments affichés',
            style: TextStyle(
              color: Colors.grey.withOpacity(0.6),
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(width: 8),
              Text(
                '$_currentPage/$_totalPages',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double ratio) {
    if (ratio >= 0.8) return Colors.green;
    if (ratio >= 0.5) return Colors.orange;
    return Colors.red;
  }
}