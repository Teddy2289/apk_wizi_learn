import 'package:flutter/material.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';

class FormateurViewCard extends StatelessWidget {
  final List<Map<String, dynamic>> formateurs;
  final int currentPage;
  final int lastPage;
  final int total;
  final Function(int page) onPageChanged;
  final VoidCallback? onFormateurTap;

  const FormateurViewCard({
    super.key,
    required this.formateurs,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.onPageChanged,
    this.onFormateurTap,
  });

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
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.school, color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vue par Formateur',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: FormateurTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        '$total formateur${total > 1 ? 's' : ''} actif${total > 1 ? 's' : ''}',
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
            child: formateurs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 40, color: FormateurTheme.border),
                        const SizedBox(height: 12),
                        const Text(
                          'Aucun formateur',
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
                    itemCount: formateurs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final formateur = formateurs[index];
                      return _buildFormateurItem(formateur);
                    },
                  ),
          ),

          // Pagination
          if (lastPage > 1)
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
                    'Page $currentPage / $lastPage',
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
                        onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                        iconSize: 20,
                        color: FormateurTheme.textSecondary,
                        disabledColor: FormateurTheme.border,
                      ),
                      IconButton(
                        onPressed: currentPage < lastPage ? () => onPageChanged(currentPage + 1) : null,
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

  Widget _buildFormateurItem(Map<String, dynamic> formateur) {
    final prenom = formateur['prenom']?.toString() ?? '';
    final nom = formateur['nom']?.toString() ?? '';
    final totalStagiaires = formateur['total_stagiaires'] ?? 0;
    final initials = '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase();

    return InkWell(
      onTap: onFormateurTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FormateurTheme.border.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.01),
                  ],
                ),
                border: Border.all(color: FormateurTheme.border),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: FormateurTheme.textSecondary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$prenom $nom',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: FormateurTheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 12, color: FormateurTheme.textTertiary),
                      const SizedBox(width: 6),
                      Text(
                        '$totalStagiaires stagiaire${totalStagiaires > 1 ? 's' : ''} assigné${totalStagiaires > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: FormateurTheme.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(Icons.chevron_right_rounded, color: FormateurTheme.border, size: 16),
          ],
        ),
      ),
    );
  }
}
