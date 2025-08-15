import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/stats_model.dart';
import 'package:wizi_learn/features/auth/presentation/pages/quiz_detail_page.dart';
import 'package:intl/intl.dart';

class QuizHistoryWidget extends StatefulWidget {
  final List<QuizHistory> history;

  const QuizHistoryWidget({super.key, required this.history});

  @override
  State<QuizHistoryWidget> createState() => _QuizHistoryWidgetState();
}

class _QuizHistoryWidgetState extends State<QuizHistoryWidget> {
  final int _itemsPerPage = 5;
  int _currentPage = 1;
  bool _showAllItems = false;
  int get _totalPages => (widget.history.length / _itemsPerPage).ceil();

  List<QuizHistory> get _currentPageItems {
    if (_showAllItems) {
      return widget.history;
    }
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return widget.history.sublist(
      startIndex,
      endIndex > widget.history.length ? widget.history.length : endIndex,
    );
  }

  int get _distinctQuizCount {
    final ids = widget.history.map((h) => h.quiz.id).toSet();
    return ids.length;
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      '$_distinctQuizCount quiz uniques complétés',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Row(
                      children: [
                        if (!_showAllItems)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Page $_currentPage/$_totalPages',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showAllItems = !_showAllItems;
                              if (_showAllItems) {
                                _currentPage = 1;
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _showAllItems
                                      ? theme.colorScheme.primary.withOpacity(
                                        0.1,
                                      )
                                      : theme.colorScheme.surfaceVariant
                                          .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _showAllItems
                                        ? theme.colorScheme.primary.withOpacity(
                                          0.3,
                                        )
                                        : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _showAllItems
                                      ? Icons.view_list
                                      : Icons.view_module,
                                  size: 16,
                                  color:
                                      _showAllItems
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _showAllItems ? 'Vue paginée' : 'Voir tout',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color:
                                        _showAllItems
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface
                                                .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Liste des quiz
          Flexible(
            child:
                _currentPageItems.isEmpty
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
                      separatorBuilder:
                          (_, __) => SizedBox(height: isSmallScreen ? 12 : 16),
                      itemBuilder:
                          (_, index) => _buildHistoryItem(
                            context,
                            _currentPageItems[index],
                          ),
                    ),
          ),

          // Pagination
          if (widget.history.isNotEmpty && !_showAllItems)
            _buildPaginationControls(isSmallScreen),
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
            style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, QuizHistory history) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    // Formatage de la date et heure
    final completedDate =
        DateTime.tryParse(history.completedAt) ?? DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy').format(completedDate);
    final formattedTime = DateFormat('HH:mm').format(completedDate);
    final formattedDateTime = '$formattedDate à $formattedTime';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => QuizDetailPage(
                    quizTitle: history.quiz.titre,
                    score: history.score,
                    totalQuestions: history.totalQuestions,
                    correctAnswers: history.correctAnswers,
                    timeSpent: history.timeSpent,
                    completedAt: completedDate,
                    questions: history.questions ?? [],
                  ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre et score
              Row(
                children: [
                  Icon(
                    Icons.quiz,
                    color: Theme.of(context).primaryColor,
                    size: isSmallScreen ? 20 : 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          history.quiz.titre,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Score : ${history.score} | ${history.correctAnswers}/${history.totalQuestions} bonnes réponses',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Informations détaillées
              Row(
                children: [
                  // Date et heure
                  Expanded(
                    child: _buildInfoChip(
                      context,
                      Icons.access_time,
                      formattedDateTime,
                      isSmallScreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Niveau
                  if (history.quiz.niveau != null &&
                      history.quiz.niveau!.isNotEmpty)
                    Expanded(
                      child: _buildInfoChip(
                        context,
                        Icons.trending_up,
                        history.quiz.niveau!,
                        isSmallScreen,
                        color: _getLevelColor(history.quiz.niveau!),
                      ),
                    ),
                  if (history.quiz.niveau != null &&
                      history.quiz.niveau!.isNotEmpty)
                    const SizedBox(width: 8),
                  // Formation
                  if (history.quiz.formation != null &&
                      history.quiz.formation!.titre.isNotEmpty)
                    Expanded(
                      child: _buildInfoChip(
                        context,
                        Icons.school,
                        history.quiz.formation!.titre,
                        isSmallScreen,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String label,
    bool isSmallScreen, {
    Color? color,
  }) {
    final chipColor = color ?? Theme.of(context).colorScheme.surfaceVariant;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 14 : 16, color: chipColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12,
                color: chipColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String niveau) {
    switch (niveau.toLowerCase()) {
      case 'débutant':
      case 'beginner':
        return Colors.green;
      case 'intermédiaire':
      case 'intermediate':
        return Colors.orange;
      case 'avancé':
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildScoreIndicator(double percentage, bool isSmallScreen) {
    final color = _getScoreColor(percentage / 100);
    return Container(
      width: isSmallScreen ? 48 : 56,
      height: isSmallScreen ? 48 : 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
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
        style: TextStyle(color: color, fontSize: isSmallScreen ? 12 : 13),
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
            _showAllItems
                ? '${widget.history.length} éléments affichés'
                : '${_currentPageItems.length} éléments affichés',
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
                onPressed:
                    _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
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
                onPressed:
                    _currentPage < _totalPages
                        ? () => _goToPage(_currentPage + 1)
                        : null,
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
