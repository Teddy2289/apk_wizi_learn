import 'package:flutter/material.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/features/formateur/data/models/analytics_model.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';

class OnlineStagiairesCard extends StatefulWidget {
  final List<OnlineStagiaire> stagiaires;
  final int total;
  final VoidCallback onRefresh;

  const OnlineStagiairesCard({
    super.key,
    required this.stagiaires,
    required this.total,
    required this.onRefresh,
  });

  @override
  State<OnlineStagiairesCard> createState() => _OnlineStagiairesCardState();
}

class _OnlineStagiairesCardState extends State<OnlineStagiairesCard> {
  String _searchTerm = '';

  List<OnlineStagiaire> get _filteredStagiaires {
    if (_searchTerm.isEmpty) return widget.stagiaires;
    final term = _searchTerm.toLowerCase();
    return widget.stagiaires.where((s) {
      final name = '${s.prenom} ${s.nom}'.toLowerCase();
      final email = s.email.toLowerCase();
      return name.contains(term) || email.contains(term);
    }).toList();
  }

  String _getInitials(String prenom, String nom) {
    return '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase();
  }

  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return '${date.day}/${date.month}/${date.year}';
  }

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
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF8F9FA), width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FormateurTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: FormateurTheme.accent.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.people, color: FormateurTheme.accentDark, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Stagiaires Actifs',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: FormateurTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            '${widget.total} en session',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: FormateurTheme.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchTerm = value),
                    decoration: InputDecoration(
                      hintText: 'Filtrer les connexions...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: FormateurTheme.textTertiary.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 16,
                        color: _searchTerm.isEmpty
                            ? FormateurTheme.textTertiary.withOpacity(0.3)
                            : FormateurTheme.accentDark,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: FormateurTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _filteredStagiaires.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: FormateurTheme.border),
                        const SizedBox(height: 16),
                        const Text(
                          'SILENCE RADIO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: FormateurTheme.textTertiary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _filteredStagiaires.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final stagiaire = _filteredStagiaires[index];
                      return _buildStagiaireItem(stagiaire);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStagiaireItem(OnlineStagiaire stagiaire) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: FormateurTheme.background,
                  border: Border.all(color: FormateurTheme.border),
                  image: stagiaire.avatar != null && stagiaire.avatar!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(AppConstants.getUserImageUrl(stagiaire.avatar!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: stagiaire.avatar == null || stagiaire.avatar!.isEmpty
                    ? Center(
                        child: Text(
                          _getInitials(stagiaire.prenom, stagiaire.nom),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: FormateurTheme.textSecondary,
                          ),
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: FormateurTheme.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${stagiaire.prenom} ${stagiaire.nom}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: FormateurTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _getRelativeTime(stagiaire.lastActivityAt),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: FormateurTheme.textTertiary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  stagiaire.email,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: FormateurTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (stagiaire.formations.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...stagiaire.formations.take(1).map(
                            (f) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: FormateurTheme.background,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: FormateurTheme.border.withOpacity(0.6)),
                              ),
                              child: Text(
                                f,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: FormateurTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                      if (stagiaire.formations.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: FormateurTheme.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: FormateurTheme.accent.withOpacity(0.2)),
                          ),
                          child: Text(
                            '+${stagiaire.formations.length - 1}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: FormateurTheme.accentDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
