import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/formation_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/formation_repository.dart';

class FormationDetailPage extends StatefulWidget {
  final int formationId;

  const FormationDetailPage({super.key, required this.formationId});

  @override
  State<FormationDetailPage> createState() => _FormationDetailPageState();
}

class _FormationDetailPageState extends State<FormationDetailPage> {
  late Future<Formation> _futureFormation;
  late FormationRepository _repository;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _repository = FormationRepository(apiClient: apiClient);
    _futureFormation = _repository.getFormationDetail(widget.formationId);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la formation'),
        elevation: 0,
      ),
      body: FutureBuilder<Formation>(
        future: _futureFormation,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Aucune donnée disponible'));
          }

          final formation = snapshot.data!;
          final categoryColor = _getCategoryColor(formation.category.categorie);
          final theme = Theme.of(context);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carte principale avec image et titre
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Image de la formation
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          color: categoryColor.withOpacity(0.1),
                          child: formation.imageUrl != null
                              ? Image.network(
                            '${AppConstants.baseUrlImg}/${formation.imageUrl}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.school,
                              size: 60,
                              color: categoryColor,
                            ),
                          )
                              : Center(
                            child: Icon(
                              Icons.school,
                              size: 60,
                              color: categoryColor,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Titre et catégorie
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        formation.titre,
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Chip(
                                        backgroundColor: categoryColor.withOpacity(0.2),
                                        label: Text(
                                          formation.category.categorie,
                                          style: TextStyle(
                                            color: categoryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Prix en badge mis en valeur
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: categoryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${formatPrice(formation.tarif)} €',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Durée et certification
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _buildFeatureChip(
                                  icon: Icons.timer,
                                  value: '${formation.duree}h',
                                  color: categoryColor,
                                ),
                                if (formation.certification != null)
                                  _buildFeatureChip(
                                    icon: Icons.verified,
                                    value: formation.certification!,
                                    color: categoryColor,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section Description
                _buildSectionTitle('Description'),
                const SizedBox(height: 8),
                Text(
                  formation.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                  style: theme.textTheme.bodyLarge,
                ),

                const SizedBox(height: 24),

                // Section Prérequis
                if (formation.prerequis != null) ...[
                  _buildSectionTitle('Prérequis'),
                  const SizedBox(height: 8),
                  Text(
                    formation.prerequis!,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                ],

                // Section Programme
                _buildSectionTitle('Programme de la formation'),
                const SizedBox(height: 8),
                Text(
                  'Découvrez toutes les compétences que vous allez acquérir lors de cette formation.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                if (formation.cursusPdf != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.picture_as_pdf, color: categoryColor),
                      label: Text(
                        'Voir le programme complet (PDF)',
                        style: TextStyle(color: categoryColor),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: categoryColor.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: categoryColor),
                        ),
                      ),
                      onPressed: () {
                        final pdfUrl = '${AppConstants.baseUrlImg}/${formation.cursusPdf}';
                        // TODO: Ouvrir le PDF
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Bouton d'inscription
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: categoryColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: categoryColor.withOpacity(0.3),
                    ),
                    onPressed: () {
                      // TODO: Gérer l'inscription
                    },
                    child: Text(
                      "S'inscrire à cette formation",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildFeatureChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Bureautique':
        return const Color(0xFF3D9BE9);
      case 'Langues':
        return const Color(0xFFA55E6E);
      case 'Internet':
        return const Color(0xFFFFC533);
      case 'Création':
        return const Color(0xFF9392BE);
      default:
        return Colors.grey;
    }
  }

  String formatPrice(num price) {
    final formatter = NumberFormat("#,##0", "fr_FR");
    final formatterWithDecimals = NumberFormat("#,##0.00", "fr_FR");

    if (price % 1 == 0) {
      return formatter.format(price);
    } else {
      return formatterWithDecimals.format(price);
    }
  }
}