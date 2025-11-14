import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:wizi_learn/features/auth/data/models/extended_formateur_model.dart';

class FormateurFormationsModal extends StatelessWidget {
  final ExtendedFormateur formateur;

  const FormateurFormationsModal({super.key, required this.formateur});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.school, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Formations de ${formateur.prenom} ${formateur.nom.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Découvrez l\'ensemble des formations dispensées par ce formateur',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child:
                  formateur.formations.isEmpty
                      ? _buildEmptyState()
                      : _buildFormationsList(),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune formation disponible',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ce formateur n\'a pas encore de formations attribuées',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: formateur.formations.length,
      itemBuilder: (context, index) {
        final formation = formateur.formations[index];
        return _buildFormationCard(formation, context);
      },
    );
  }

  Widget _buildFormationCard(
    ExtendedFormation formation,
    BuildContext context,
  ) {
    final category = formation.formation?.categorie ?? 'Non catégorisé';
    final categoryColor = _getCategoryColor(category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Column(
        children: [
          // Barre de couleur de catégorie
          Container(height: 4, color: categoryColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec titre et badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.book_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formation.titre,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: categoryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: categoryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description
                if (formation.description.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Html(
                      data: formation.description,
                      style: {
                        'body': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(14),
                          color: Colors.grey.shade700,
                        ),
                        'ul': Style(margin: Margins.only(bottom: 8)),
                        'li': Style(margin: Margins.only(bottom: 4)),
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Informations
                Row(
                  children: [
                    _buildInfoItem(
                      Icons.schedule,
                      formation.duree.isEmpty
                          ? 'Non spécifiée'
                          : '${formation.duree}h',
                    ),
                    // const SizedBox(width: 16),
                    // _buildInfoItem(
                    //   Icons.euro,
                    //   formation.tarif.isEmpty
                    //       ? 'Non spécifié'
                    //       : '${formation.tarif}€',
                    // ),
                    const Spacer(),
                    _buildStatusBadge(formation.statut),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildStatusBadge(int statut) {
    final statusInfo = _getStatusInfo(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: statusInfo.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusInfo.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            statusInfo.text,
            style: TextStyle(
              color: statusInfo.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'bureautique':
        return const Color(0xFF3D9BE9);
      case 'langues':
        return const Color(0xFFA55E6E);
      case 'internet':
        return const Color(0xFFFFC533);
      case 'création':
        return const Color(0xFF9392BE);
      case 'ia':
        return const Color(0xFFABDA96);
      default:
        return const Color(0xFFE0E0E0);
    }
  }

  ({String text, Color color}) _getStatusInfo(int statut) {
    switch (statut) {
      case 1:
        return (text: 'Activée', color: Colors.green);
      case 0:
        return (text: 'Désactivée', color: Colors.orange);
      default:
        return (text: 'Inconnu', color: Colors.grey);
    }
  }
}
