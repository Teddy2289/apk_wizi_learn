import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
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
      print(
        '🟡 DEBUG: Début de l\'inscription pour la formation ${widget.formationId}',
      );
      print('🟡 DEBUG: Formation ID: ${widget.formationId}');

      // Appel à l'API d'inscription
      final response = await _repository.inscrireAFormation(widget.formationId);

      // DEBUG: Afficher la réponse de l'API
      print('🟢 DEBUG: Réponse complète: $response');
      print('🟢 DEBUG: Type de réponse: ${response.runtimeType}');

      // Vérifier le succès dans la réponse
      if (response['success'] == true) {
        setState(() {
          _success = true;
          _successMessage =
              response['message'] ??
              'Inscription réussie, mails et notification envoyés.';
          _showSuccessModal = true;
        });
        print('🟢 DEBUG: Inscription réussie - Modal affiché');
      } else {
        throw Exception(
          response['error'] ?? 'Erreur inconnue lors de l\'inscription',
        );
      }
    } catch (e) {
      // DEBUG détaillé de l'erreur
      print('🔴 DEBUG: ERREUR lors de l\'inscription:');
      print('🔴 DEBUG: Type d\'erreur: ${e.runtimeType}');
      print('🔴 DEBUG: Message d\'erreur: $e');

      // Si c'est une erreur Dio, afficher plus de détails
      if (e is DioException) {
        print('🔴 DEBUG: Erreur Dio détectée:');
        print('🔴 DEBUG: - Type: ${e.type}');
        print('🔴 DEBUG: - Message: ${e.message}');
        print('🔴 DEBUG: - Response: ${e.response}');
        print('🔴 DEBUG: - Status Code: ${e.response?.statusCode}');
        print('🔴 DEBUG: - Data: ${e.response?.data}');

        // Extraire le message d'erreur de la réponse
        final errorData = e.response?.data;
        if (errorData is Map) {
          final serverError =
              errorData['error'] ?? errorData['details'] ?? 'Erreur serveur';
          final serverMessage = errorData['message'] ?? serverError;
          _successMessage = serverMessage.toString();

          print('🔴 DEBUG: Message d\'erreur du serveur: $_successMessage');
        }

        // Analyser le statut HTTP
        if (e.response != null) {
          final statusCode = e.response!.statusCode;
          print('🔴 DEBUG: Status Code: $statusCode');

          // Messages d'erreur spécifiques selon le statut
          if (statusCode == 401) {
            _successMessage =
                'Erreur d\'authentification. Veuillez vous reconnecter.';
          } else if (statusCode == 403) {
            _successMessage =
                'Accès refusé. Vous n\'avez pas les permissions nécessaires.';
          } else if (statusCode == 404) {
            _successMessage = 'Formation non trouvée.';
          } else if (statusCode == 409) {
            _successMessage = 'Vous êtes déjà inscrit à cette formation.';
          } else if (statusCode == 422) {
            _successMessage =
                'Données invalides. Veuillez vérifier les informations.';
          } else if (statusCode! >= 500) {
            _successMessage = 'Erreur serveur. Veuillez réessayer plus tard.';
          }
        }
      } else if (e is Exception) {
        _successMessage = e.toString();
      }

      setState(() {
        _error = true;
      });

      // Afficher un SnackBar avec le message d'erreur détaillé
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _successMessage.isNotEmpty
                ? _successMessage
                : 'Erreur lors de l\'inscription. Veuillez réessayer.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('🟡 DEBUG: Chargement terminé - isLoading: $_isLoading');
    }
  }

  void _closeSuccessModal() {
    setState(() {
      _showSuccessModal = false;
      _successMessage = '';
    });
  }

  void _navigateToCatalogue() {
    _closeSuccessModal();
    Navigator.pop(context);
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (context) => TrainingPage()),
    // );
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
              // DEBUG du chargement des données de formation
              if (snapshot.connectionState == ConnectionState.waiting) {
                print('🟡 DEBUG: Chargement des détails de la formation...');
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                print(
                  '🔴 DEBUG: Erreur lors du chargement des détails: ${snapshot.error}',
                );
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
                          print('🟡 DEBUG: Réessai du chargement des détails');
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
                print('🔴 DEBUG: Aucune donnée de formation disponible');
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

              print('🟢 DEBUG: Formation chargée - ${formation.titre}');

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
                              AppConstants.getMediaUrl(formation.imageUrl),
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
                              // Removed as per user request

                            ],
                          ),

                          const SizedBox(height: 24),

                          // Infos complémentaires (lieu, niveau, public cible, nombre participants)
                          _buildSection(
                            title: 'Informations pratiques',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    if (formation.niveau != null &&
                                        formation.niveau!.isNotEmpty)
                                      _buildInfoTile(
                                        icon: Icons.school_outlined,
                                        label: 'Niveau',
                                        value: formation.niveau!,
                                        color: categoryColor,
                                      ),
                                    if (formation.publicCible != null &&
                                        formation.publicCible!.isNotEmpty)
                                      _buildInfoTile(
                                        icon: Icons.group_outlined,
                                        label: 'Public cible',
                                        value: formation.publicCible!,
                                        color: categoryColor,
                                      ),
                                    if (formation.nombreParticipants != null)
                                      _buildInfoTile(
                                        icon: Icons.people_alt_outlined,
                                        label: 'Participants',
                                        value:
                                            formation.nombreParticipants
                                                .toString(),
                                        color: categoryColor,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Infos rapides
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildInfoTile(
                                icon: Icons.timer_outlined,
                                label: 'Durée',
                                value: 'A partir de ${formation.duree} heures',
                                color: categoryColor,
                              ),

                              // Bouton de téléchargement PDF remplaçant les deux _buildInfoTile
                              if (formation.cursusPdf != null &&
                                  formation.cursusPdf!.isNotEmpty)
                                _buildPdfDownloadButton(
                                  categoryColor: categoryColor,
                                  formation: formation,
                                ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Section Description
                          _buildSection(
                            title: 'Description',
                            child: Html(
                              data: formation.description,
                              style: {
                                "body": Style(
                                  fontSize: FontSize(16.0),
                                  lineHeight: LineHeight(1.6),
                                  color:
                                      isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[800],
                                ),
                              },
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

                          // Section Objectifs (HTML)
                          if (formation.objectifs != null &&
                              formation.objectifs!.isNotEmpty)
                            _buildSection(
                              title: 'Objectifs',
                              child: Html(
                                data: formation.objectifs!,
                                style: {
                                  "body": Style(
                                    fontSize: FontSize(16.0),
                                    lineHeight: LineHeight(1.6),
                                    color:
                                        isDarkMode
                                            ? Colors.grey[300]
                                            : Colors.grey[800],
                                  ),
                                },
                              ),
                            ),

                          // Modalités
                          if (formation.modalites != null &&
                              formation.modalites!.isNotEmpty)
                            _buildSection(
                              title: 'Modalités',
                              child: Html(
                                data: formation.modalites!,
                                style: {
                                  "body": Style(
                                    fontSize: FontSize(16.0),
                                    lineHeight: LineHeight(1.6),
                                    color:
                                        isDarkMode
                                            ? Colors.grey[300]
                                            : Colors.grey[800],
                                  ),
                                },
                              ),
                            ),

                          // Modalités d'accompagnement
                          if (formation.modalitesAccompagnement != null &&
                              formation.modalitesAccompagnement!.isNotEmpty)
                            _buildSection(
                              title: 'Modalités d\'accompagnement',
                              child: Html(
                                data: formation.modalitesAccompagnement!,
                                style: {
                                  "body": Style(
                                    fontSize: FontSize(16.0),
                                    lineHeight: LineHeight(1.6),
                                    color:
                                        isDarkMode
                                            ? Colors.grey[300]
                                            : Colors.grey[800],
                                  ),
                                },
                              ),
                            ),

                          // Moyens pédagogiques
                          if (formation.moyensPedagogiques != null &&
                              formation.moyensPedagogiques!.isNotEmpty)
                            _buildSection(
                              title: 'Moyens pédagogiques',
                              child: Html(
                                data: formation.moyensPedagogiques!,
                                style: {
                                  "body": Style(
                                    fontSize: FontSize(16.0),
                                    lineHeight: LineHeight(1.6),
                                    color:
                                        isDarkMode
                                            ? Colors.grey[300]
                                            : Colors.grey[800],
                                  ),
                                },
                              ),
                            ),

                          // Modalités de suivi
                          if (formation.modalitesSuivi != null &&
                              formation.modalitesSuivi!.isNotEmpty)
                            _buildSection(
                              title: 'Modalités de suivi',
                              child: Html(
                                data: formation.modalitesSuivi!,
                                style: {
                                  "body": Style(
                                    fontSize: FontSize(16.0),
                                    lineHeight: LineHeight(1.6),
                                    color:
                                        isDarkMode
                                            ? Colors.grey[300]
                                            : Colors.grey[800],
                                  ),
                                },
                              ),
                            ),

                          // Évaluation
                          if (formation.evaluation != null &&
                              formation.evaluation!.isNotEmpty)
                            _buildSection(
                              title: 'Évaluation',
                              child: Text(
                                formation.evaluation!,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  height: 1.6,
                                  color:
                                      isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[800],
                                ),
                              ),
                            ),

                          const SizedBox(height: 40),
                          // Section Programme (prefer HTML from API, fallback to PDF)
                          if (formation.programme != null &&
                              formation.programme!.isNotEmpty)
                            _buildSection(
                              title: 'Programme détaillé',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Html(
                                    data: formation.programme!,
                                    style: {
                                      "body": Style(
                                        fontSize: FontSize(16.0),
                                        lineHeight: LineHeight(1.6),
                                        color:
                                            isDarkMode
                                                ? Colors.grey[300]
                                                : Colors.grey[800],
                                      ),
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            )
                          else
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final pdfUrl =
                                            AppConstants.getMediaUrl(formation.cursusPdf);
                                        print(
                                          '🟡 DEBUG: Tentative d\'ouverture du PDF: $pdfUrl',
                                        );
                                        if (await canLaunchUrl(
                                          Uri.parse(pdfUrl),
                                        )) {
                                          await launchUrl(Uri.parse(pdfUrl));
                                          print(
                                            '🟢 DEBUG: PDF ouvert avec succès',
                                          );
                                        } else {
                                          print(
                                            '🔴 DEBUG: Impossible d\'ouvrir le PDF',
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Impossible d\'ouvrir le PDF.',
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ),
                          // Bouton d'inscription avec état de debug
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

                          // Section de debug (optionnelle - à enlever en production)
                          if (_error) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Informations de débogage:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _successMessage,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

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
            softWrap: true, // ✅ autorise le retour à la ligne
            overflow: TextOverflow.visible, // ✅ évite le débordement masqué
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          // ✅ Utilisation d'un Expanded pour empêcher le débordement du texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  softWrap: true,
                  overflow:
                      TextOverflow.ellipsis, // coupe proprement si trop long
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfDownloadButton({
    required Color categoryColor,
    required Formation formation,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          final pdfUrl = AppConstants.getMediaUrl(formation.cursusPdf);
          print('🟡 DEBUG: Tentative d\'ouverture du PDF: $pdfUrl');
          if (await canLaunchUrl(Uri.parse(pdfUrl))) {
            await launchUrl(Uri.parse(pdfUrl));
            print('🟢 DEBUG: PDF ouvert avec succès');
          } else {
            print('🔴 DEBUG: Impossible d\'ouvrir le PDF');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Impossible d\'ouvrir le PDF.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf, size: 20, color: categoryColor),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Programme de formation',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Télécharger le PDF',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: categoryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    // Palette de couleurs harmonieuses
    final colors = {
      'Bureautique': const Color(0xFF3D9BE9),
      'IA': const Color(0xFFABDA96),
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
                              border: Border.all(color: Colors.grey[200]!),
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
                              Icon(Icons.explore_outlined, size: 20),
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

  return formatted;
}
