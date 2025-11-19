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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.all(isLandscape ? 8 : (isSmallScreen ? 12 : 16)),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isLandscape ? 12 : 16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header compact en paysage
          Padding(
            padding: EdgeInsets.all(isLandscape ? 12 : (isSmallScreen ? 16 : 20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.history_outlined,
                          color: theme.primaryColor,
                          size: isLandscape ? 20 : (isSmallScreen ? 24 : 28),
                        ),
                        SizedBox(width: isLandscape ? 8 : (isSmallScreen ? 12 : 16)),
                        Text(
                          isLandscape ? 'Historique' : 'Historique des Quiz',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            fontSize: isLandscape ? 18 : null,
                          ),
                        ),
                      ],
                    ),

                    // Compteur et bouton vue tout SUR LA MÊME LIGNE en paysage
                    isLandscape
                        ? Row(
                      children: [
                        Text(
                          '$_distinctQuizCount quiz',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildViewToggleButton(theme, isLandscape),
                      ],
                    )
                        : Container(),
                  ],
                ),

                // Ligne inférieure seulement en portrait
                if (!isLandscape) ...[
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_distinctQuizCount quiz joués',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      _buildViewToggleButton(theme, isLandscape),
                    ],
                  ),
                ],
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
                left: isLandscape ? 12 : (isSmallScreen ? 16 : 20),
                right: isLandscape ? 12 : (isSmallScreen ? 16 : 20),
                bottom: isLandscape ? 12 : 16,
              ),
              itemCount: _currentPageItems.length,
              separatorBuilder: (_, __) => SizedBox(height: isLandscape ? 8 : (isSmallScreen ? 12 : 16)),
              itemBuilder: (_, index) => _buildHistoryItem(
                context,
                _currentPageItems[index],
                isLandscape,
              ),
            ),
          ),

          // Pagination
          if (widget.history.isNotEmpty && !_showAllItems)
            _buildPaginationControls(isLandscape),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton(ThemeData theme, bool isLandscape) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAllItems = !_showAllItems;
          if (_showAllItems) {
            _currentPage = 1;
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 10 : 12,
          vertical: isLandscape ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: _showAllItems
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(isLandscape ? 8 : 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showAllItems ? Icons.view_list : Icons.view_module,
              size: isLandscape ? 14 : 16,
              color: _showAllItems
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              _showAllItems ? 'Paginé' : 'Tout voir',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: isLandscape ? 11 : null,
                color: _showAllItems
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
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

  Widget _buildHistoryItem(BuildContext context, QuizHistory history, bool isLandscape) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final categoryColor = _getCategoryColor(history.quiz.formation.categorie);

    // Formatage de la date et heure
    final completedDate = DateTime.tryParse(history.completedAt) ?? DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy').format(completedDate);
    final formattedTime = DateFormat('HH:mm').format(completedDate);
    final formattedDateTime = isLandscape ? '$formattedDate $formattedTime' : '$formattedDate à $formattedTime';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizDetailPage(
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
        borderRadius: BorderRadius.circular(isLandscape ? 8 : 12),
        child: Padding(
          padding: EdgeInsets.all(isLandscape ? 12 : 16),
          child: isLandscape
              ? _buildLandscapeHistoryItem(history, categoryColor, formattedDateTime, isSmallScreen)
              : _buildPortraitHistoryItem(history, categoryColor, formattedDateTime, isSmallScreen),
        ),
      ),
    );
  }

  Widget _buildPortraitHistoryItem(QuizHistory history, Color categoryColor, String formattedDateTime, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec titre et score
        Row(
          children: [
            Icon(
              Icons.quiz,
              color: categoryColor,
              size: isSmallScreen ? 20 : 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    history.quiz.titre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Score : ${history.score} | ${history.correctAnswers}/${history.totalQuestions} bonnes réponses',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
            if (history.quiz.niveau.isNotEmpty)
              Expanded(
                child: _buildInfoChip(
                  context,
                  Icons.trending_up,
                  history.quiz.niveau,
                  isSmallScreen,
                  color: _getLevelColor(history.quiz.niveau),
                ),
              ),
            if (history.quiz.niveau.isNotEmpty) const SizedBox(width: 8),
            // Formation
            if (history.quiz.formation.titre.isNotEmpty)
              Expanded(
                child: _buildInfoChip(
                  context,
                  Icons.school,
                  history.quiz.formation.titre,
                  isSmallScreen,
                  color: categoryColor,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLandscapeHistoryItem(QuizHistory history, Color categoryColor, String formattedDateTime, bool isSmallScreen) {
    return Row(
      children: [
        // Icône quiz
        Icon(
          Icons.quiz,
          color: categoryColor,
          size: 16,
        ),
        const SizedBox(width: 8),

        // Titre et informations principales
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                history.quiz.titre,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${history.correctAnswers}/${history.totalQuestions} réponses • Score: ${history.score}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        // Informations secondaires compactes
        Expanded(
          flex: 2,
          child: Row(
            children: [
              _buildCompactInfo(Icons.access_time, formattedDateTime, context),
              if (history.quiz.niveau.isNotEmpty) ...[
                const SizedBox(width: 6),
                _buildCompactInfo(Icons.trending_up, history.quiz.niveau, context, color: _getLevelColor(history.quiz.niveau)),
              ],
            ],
          ),
        ),

        // Indicateur de score
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getScoreColor(history.score / 100).withOpacity(0.1),
          ),
          child: Center(
            child: Text(
              '${history.score}',
              style: TextStyle(
                color: _getScoreColor(history.score / 100),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),

        const SizedBox(width: 4),
        Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          size: 16,
        ),
      ],
    );
  }

  Widget _buildCompactInfo(IconData icon, String text, BuildContext context, {Color? color}) {
    final defaultColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: color ?? defaultColor,
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color ?? defaultColor,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(
      BuildContext context,
      IconData icon,
      String label,
      bool isSmallScreen, {
        Color? color,
      }) {
    final chipColor = color ?? Theme.of(context).colorScheme.surfaceContainerHighest;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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

  Color _getCategoryColor(String? category) {
    final theme = Theme.of(context);
    if (category == null) return theme.colorScheme.primary;
    final cat = category.trim().toLowerCase();
    switch (cat) {
      case 'bureautique':
        return const Color(0xFF3D9BE9);
      case 'langues':
        return const Color(0xFFA55E6E);
      case 'internet':
        return const Color(0xFFFFC533);
      case 'creation':
        return const Color(0xFF9392BE);
      case 'IA':
        return const Color(0xFFABDA96);
      default:
        return theme.colorScheme.primary;
    }
  }

  Widget _buildPaginationControls(bool isLandscape) {
    return Padding(
      padding: EdgeInsets.all(isLandscape ? 8 : (isLandscape ? 12 : 16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _showAllItems
                ? '${widget.history.length} éléments'
                : '${_currentPageItems.length} éléments',
            style: TextStyle(
              color: Colors.grey.withOpacity(0.6),
              fontSize: isLandscape ? 11 : (isLandscape ? 12 : 14),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, size: isLandscape ? 18 : 24),
                onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                color: Theme.of(context).primaryColor,
                padding: EdgeInsets.all(isLandscape ? 4 : 8),
              ),
              SizedBox(width: isLandscape ? 4 : 8),
              Text(
                '$_currentPage/$_totalPages',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isLandscape ? 12 : (isLandscape ? 14 : 16),
                ),
              ),
              SizedBox(width: isLandscape ? 4 : 8),
              IconButton(
                icon: Icon(Icons.chevron_right, size: isLandscape ? 18 : 24),
                onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
                color: Theme.of(context).primaryColor,
                padding: EdgeInsets.all(isLandscape ? 4 : 8),
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