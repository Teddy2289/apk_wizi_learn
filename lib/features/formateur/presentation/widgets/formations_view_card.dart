import 'package:flutter/material.dart';
import 'package:wizi_learn/features/formateur/data/models/analytics_model.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';

class FormationsViewCard extends StatefulWidget {
  final List<FormationDashboardStats> formations;
  final int currentPage;
  final int lastPage;
  final int total;
  final Function(int page) onPageChanged;
  final VoidCallback? onFormationTap;

  const FormationsViewCard({
    super.key,
    required this.formations,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.onPageChanged,
    this.onFormationTap,
  });

  @override
  State<FormationsViewCard> createState() => _FormationsViewCardState();
}

class _FormationsViewCardState extends State<FormationsViewCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: FormateurTheme.border),
        boxShadow: FormateurTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: FormateurTheme.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.auto_stories_rounded, color: Colors.purple, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vue par Formation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: FormateurTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        '${widget.total} catalogue${widget.total > 1 ? 's' : ''} actif${widget.total > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: FormateurTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: widget.formations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined, size: 48, color: FormateurTheme.border),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucune formation',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: FormateurTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.formations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final formation = widget.formations[index];
                      return _buildFormationItem(formation);
                    },
                  ),
          ),

          // Pagination
          if (widget.lastPage > 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                border: Border(top: BorderSide(color: FormateurTheme.border, width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page ${widget.currentPage} / ${widget.lastPage}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: FormateurTheme.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.currentPage > 1
                            ? () => widget.onPageChanged(widget.currentPage - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                        iconSize: 20,
                        color: FormateurTheme.textSecondary,
                        disabledColor: FormateurTheme.border,
                      ),
                      IconButton(
                        onPressed: widget.currentPage < widget.lastPage
                            ? () => widget.onPageChanged(widget.currentPage + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                        iconSize: 20,
                        color: FormateurTheme.textSecondary,
                        disabledColor: FormateurTheme.border,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormationItem(FormationDashboardStats formation) {
    return InkWell(
      onTap: widget.onFormationTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FormateurTheme.border.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    formation.titre,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: FormateurTheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: FormateurTheme.border, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatChip(
                  Icons.people_outline,
                  '${formation.studentCount} inscrits',
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  Icons.circle,
                  '${formation.activeStudents} actifs',
                  iconColor: FormateurTheme.success,
                  iconSize: 6,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MOYENNE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: FormateurTheme.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: formation.avgScore >= 70
                        ? FormateurTheme.accent.withOpacity(0.1)
                        : FormateurTheme.textTertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: formation.avgScore >= 70
                          ? FormateurTheme.accent.withOpacity(0.3)
                          : FormateurTheme.border,
                    ),
                  ),
                  child: Text(
                    '${formation.avgScore.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: formation.avgScore >= 70
                          ? FormateurTheme.accentDark
                          : FormateurTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, {Color? iconColor, double? iconSize}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize ?? 12, color: iconColor ?? FormateurTheme.textSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: FormateurTheme.textSecondary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
