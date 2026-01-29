import 'package:flutter/material.dart';
import 'package:wizi_learn/features/formateur/data/models/analytics_model.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';

class InactiveStagiairesTable extends StatelessWidget {
  final List<InactiveStagiaire> stagiaires;
  final bool loading;

  const InactiveStagiairesTable({
    super.key,
    required this.stagiaires,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: FormateurTheme.border),
        boxShadow: FormateurTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FormateurTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.warning_rounded, color: FormateurTheme.error, size: 20),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stagiaires Inactifs',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: FormateurTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Apprenants nécessitant une relance pédagogique',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: FormateurTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Table
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (stagiaires.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: FormateurTheme.success.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    const Text(
                      'Tous les stagiaires sont actifs !',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FormateurTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 96,
                ),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(FormateurTheme.background),
                  headingRowHeight: 56,
                  dataRowHeight: 64,
                  horizontalMargin: 0,
                  columnSpacing: 24,
                  decoration: BoxDecoration(
                    border: Border.all(color: FormateurTheme.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'STAGIAIRE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: FormateurTheme.textTertiary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'EMAIL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: FormateurTheme.textTertiary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'DERNIÈRE CONNEXION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: FormateurTheme.textTertiary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'JOURS D\'INACTIVITÉ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: FormateurTheme.textTertiary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'FORMATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: FormateurTheme.textTertiary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                  rows: stagiaires.map((stagiaire) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: FormateurTheme.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: FormateurTheme.border),
                                ),
                                child: Center(
                                  child: Text(
                                    '${stagiaire.prenom[0]}${stagiaire.nom[0]}'.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: FormateurTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  '${stagiaire.prenom} ${stagiaire.nom}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: FormateurTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            stagiaire.email,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: FormateurTheme.textSecondary,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            stagiaire.lastSeenAt != null
                                ? _formatDate(stagiaire.lastSeenAt!)
                                : 'Jamais',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: FormateurTheme.textSecondary,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: stagiaire.daysInactive > 14
                                  ? FormateurTheme.error.withOpacity(0.1)
                                  : FormateurTheme.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${stagiaire.daysInactive} jours',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: stagiaire.daysInactive > 14
                                    ? FormateurTheme.error
                                    : FormateurTheme.accentDark,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            stagiaire.formationNom ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: FormateurTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
