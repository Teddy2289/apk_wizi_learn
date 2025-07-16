import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isLoading = false;
  bool _success = false;
  bool _error = false;

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

  Future<void> _inscrireAFormation() async {
    setState(() {
      _isLoading = true;
      _success = false;
      _error = false;
    });
    try {
      await _repository.inscrireAFormation(widget.formationId);
      setState(() {
        _success = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscription réussie !'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _error = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'inscription. Veuillez réessayer.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Formation>(
        future: _futureFormation,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Une erreur est survenue',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Veuillez réessayer plus tard',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _futureFormation = _repository.getFormationDetail(widget.formationId);
                      });
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune donnée disponible',
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
            );
          }

          final formation = snapshot.data!;
          final categoryColor = _getCategoryColor(formation.category.categorie);

          return CustomScrollView(
            slivers: [
              // Image header avec effet parallax
              SliverAppBar(
                expandedHeight: 280,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Hero(
                    tag: 'formation-${formation.id}',
                    child: CachedNetworkImage(
                      imageUrl: '${AppConstants.baseUrlImg}/${formation.imageUrl}',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: categoryColor.withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            Icons.school,
                            size: 80,
                            color: categoryColor,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: categoryColor.withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            Icons.school,
                            size: 80,
                            color: categoryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Contenu principal
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                                    color: isDarkMode ? Colors.white : Colors.black,
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
                          // Prix
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: categoryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${formation.tarif.toInt()} €',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Infos rapides
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildInfoTile(
                            icon: Icons.timer_outlined,
                            label: 'Durée',
                            value: '${formation.duree} heures',
                            color: categoryColor,
                          ),
                          if (formation.certification != null &&
                              formation.certification!.isNotEmpty)
                            _buildInfoTile(
                              icon: Icons.verified_outlined,
                              label: 'Certification',
                              value: formation.certification!,
                              color: categoryColor,
                            ),
                          _buildInfoTile(
                            icon: Icons.calendar_today_outlined,
                            label: 'Début',
                            value: 'À tout moment',
                            color: categoryColor,
                          ),
                          _buildInfoTile(
                            icon: Icons.people_outline,
                            label: 'Format',
                            value: 'En ligne',
                            color: categoryColor,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Section Description
                      _buildSection(
                        title: 'Description',
                        child: Text(
                          formation.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[800],
                          ),
                        ),
                      ),

                      // Section Prérequis
                      if (formation.prerequis != null &&
                          formation.prerequis!.isNotEmpty)
                        _buildSection(
                          title: 'Prérequis',
                          child: Text(
                            formation.prerequis!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              color: isDarkMode
                                  ? Colors.grey[300]
                                  : Colors.grey[800],
                            ),
                          ),
                        ),

                      // Section Programme
                      _buildSection(
                        title: 'Programme détaillé',
                        child: Column(
                          children: [
                            Text(
                              'Cette formation couvre tous les aspects essentiels pour maîtriser le sujet. Le programme complet est disponible au format PDF.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.6,
                                color: isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (formation.cursusPdf != null &&
                                formation.cursusPdf!.isNotEmpty)
                              OutlinedButton.icon(
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Télécharger le programme'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 16),
                                  side: BorderSide(color: categoryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  final pdfUrl =
                                      '${AppConstants.baseUrlImg}/${formation.cursusPdf}';
                                  if (await canLaunchUrl(Uri.parse(pdfUrl))) {
                                    await launchUrl(Uri.parse(pdfUrl));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Impossible d\'ouvrir le PDF.'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

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
                            elevation: 4,
                            shadowColor: categoryColor.withOpacity(0.3),
                          ),
                          onPressed: _isLoading ? null : _inscrireAFormation,
                          child: _isLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_success)
                                const Icon(Icons.check_circle, size: 20),
                              if (_error)
                                const Icon(Icons.error_outline, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _success
                                    ? "Inscription confirmée"
                                    : _error
                                    ? "Erreur, réessayer"
                                    : "S'inscrire maintenant",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    // Palette de couleurs harmonieuses
    final colors = {
      'Bureautique': const Color(0xFF4E79A7),
      'Langues': const Color(0xFFE15759),
      'Internet': const Color(0xFFF28E2B),
      'Création': const Color(0xFF76B7B2),
      'Développement': const Color(0xFF59A14F),
      'Design': const Color(0xFFEDC948),
      'Marketing': const Color(0xFFB07AA1),
    };
    return colors[category] ?? const Color(0xFF79706E);
  }
}