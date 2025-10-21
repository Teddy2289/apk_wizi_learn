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
import 'package:wizi_learn/features/auth/presentation/pages/training_page.dart';

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
  bool _showSuccessModal = false;
  String _successMessage = '';
  String _currentFormationTitle = '';

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
      // Simuler la réponse de l'API avec un message de succès
      // Dans un cas réel, vous récupéreriez le message de l'API
      await _repository.inscrireAFormation(widget.formationId);
      setState(() {
        _success = true;
        _successMessage = 'Inscription réussie, mails et notification envoyés.';
        _showSuccessModal = true;
      });
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

  void _closeSuccessModal() {
    setState(() {
      _showSuccessModal = false;
      _successMessage = '';
    });
    // Optionnel : navigation vers le catalogue
    // Navigator.pushReplacementNamed(context, '/catalogue');
  }
  void _navigateToCatalogue() {
    _closeSuccessModal();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => TrainingPage()),
    );
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
      body: Stack(
        children: [
          FutureBuilder<Formation>(
            future: _futureFormation,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
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
                            _futureFormation = _repository.getFormationDetail(
                              widget.formationId,
                            );
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
                      const Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.grey,
                      ),
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
              _currentFormationTitle = formation.titre;
              final categoryColor = _getCategoryColor(
                formation.category.categorie,
              );

              return CustomScrollView(
                slivers: [
                  // Image header avec effet parallax
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.transparent,
                    expandedHeight: 130,
                    stretch: true,
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [StretchMode.zoomBackground],
                      background: Hero(
                        tag: 'formation-${formation.id}',
                        child: CachedNetworkImage(
                          imageUrl:
                              '${AppConstants.baseUrlImg}/${formation.imageUrl}',
                          fit: BoxFit.fitHeight,
                          placeholder:
                              (context, url) => Container(
                                color: categoryColor,
                                child: Center(
                                  child: Icon(
                                    Icons.school,
                                    size: 80,
                                    color: categoryColor,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
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
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Chip(
                                      backgroundColor: categoryColor
                                          .withOpacity(0.2),
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
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  ('${formatPrice(formation.tarif.toInt())} €'),
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
                              formation.description.replaceAll(
                                RegExp(r'<[^>]*>'),
                                '',
                              ),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.6,
                                color:
                                    isDarkMode
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
                                  color:
                                      isDarkMode
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
                                    color:
                                        isDarkMode
                                            ? Colors.grey[300]
                                            : Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (formation.cursusPdf != null &&
                                    formation.cursusPdf!.isNotEmpty)
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.picture_as_pdf),
                                    label: const Text(
                                      'Télécharger le programme',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      side: BorderSide(color: categoryColor),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () async {
                                      final pdfUrl =
                                          '${AppConstants.baseUrlImg}/${formation.cursusPdf}';
                                      if (await canLaunchUrl(
                                        Uri.parse(pdfUrl),
                                      )) {
                                        await launchUrl(Uri.parse(pdfUrl));
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Impossible d\'ouvrir le PDF.',
                                            ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: categoryColor.withOpacity(0.3),
                              ),
                              onPressed:
                                  _isLoading ? null : _inscrireAFormation,
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (_success)
                                            const Icon(
                                              Icons.check_circle,
                                              size: 20,
                                            ),
                                          if (_error)
                                            const Icon(
                                              Icons.error_outline,
                                              size: 20,
                                            ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _success
                                                ? "Demande d'inscription envoyée"
                                                : _error
                                                ? "Erreur, réessayer"
                                                : "S'inscrire maintenant",
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
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

          // Modal de succès
          if (_showSuccessModal)
            _SuccessModal(
              isOpen: _showSuccessModal,
              onClose: _closeSuccessModal,
              onContinue: _navigateToCatalogue,
              formationTitle: _currentFormationTitle,
              message: _successMessage,
            ),
        ],
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
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
      'Bureautique': const Color(0xFF3D9BE9),
      'Langues': const Color(0xFFA55E6E),
      'Internet': const Color(0xFFFFC533),
      'Création': const Color(0xFF9392BE),
    };
    return colors[category] ?? const Color(0xFF79706E);
  }
}

// Composant Modal pour le succès de l'inscription
class _SuccessModal extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final VoidCallback onContinue;
  final String message;
  final String formationTitle;

  const _SuccessModal({
    required this.isOpen,
    required this.onClose,
    required this.onContinue,
    required this.message,
    required this.formationTitle,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onClose, // Fermer le modal en tapant à l'extérieur
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Empêcher la fermeture en tapant à l'intérieur
            child: Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header avec icône et titre
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icône de succès
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9C4),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              size: 24,
                              color: Color(0xFFF57C00),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Titre
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Demande d\'inscription envoyée avec succès !',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Bouton fermeture aligné à droite
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    onPressed: onClose,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Contenu principal
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Votre demande d\'inscription a été envoyée pour la formation :',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Nom de la formation
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[200]!,
                              ),
                            ),
                            child: Text(
                              formationTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Message de confirmation
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFECB3),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Color(0xFFF57C00),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF7D6608),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Bouton d'action principal
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.explore_outlined,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Continuer à explorer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Bouton secondaire
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: onClose,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Rester sur cette page',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
String formatPrice(num price) {
  final formatter = NumberFormat("#,##0.##", "fr_FR");
  // Format classique avec séparateur français (souvent espace insécable)
  String formatted = formatter.format(price);
  // Remplace les espaces insécables (\u202F ou \u00A0) par un espace normal " "
  formatted = formatted.replaceAll(RegExp(r'[\u202F\u00A0]'), ' ');
  // Double l'espace pour qu'il soit visuellement bien marqué
  formatted = formatted.replaceAll(' ', ' ');

  return "$formatted";
}
