import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/features/auth/data/models/formation_model.dart';
import 'package:wizi_learn/features/auth/presentation/pages/detail_formation_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/repositories/formation_repository.dart';

class RandomFormationsWidget extends StatelessWidget {
  final List<Formation> formations;
  final VoidCallback? onRefresh;
  final Function(String message, String formationTitle)?
  onInscriptionSuccess; // Nouveau callback

  const RandomFormationsWidget({
    super.key,
    required this.formations,
    this.onRefresh,
    this.onInscriptionSuccess, // Ajout du callback
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;
    final cardWidth =
        screenWidth < 350
            ? 160.0
            : (screenWidth < 450 ? 180.0 : screenWidth / 2.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        formations.isEmpty
            ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  "Aucune formation disponible pour le moment.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
            : SizedBox(
              child: Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final screenHeight = MediaQuery.of(context).size.height;
                  double cardHeight;
                  if (isWide) {
                    cardHeight = screenHeight * 0.32;
                    if (cardHeight < 320) cardHeight = 320;
                    if (cardHeight > 520) cardHeight = 520;
                  } else {
                    cardHeight = screenHeight * 0.26;
                    if (cardHeight < 240) cardHeight = 240;
                    if (cardHeight > 360) cardHeight = 360;
                  }

                  final viewportFraction =
                      isWide
                          ? 0.45
                          : (cardWidth / screenWidth).clamp(0.35, 0.75);
                  final pageController = PageController(
                    viewportFraction: viewportFraction,
                  );

                  return SizedBox(
                    height: cardHeight,
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: formations.length,
                      padEnds: false,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final itemWidth = screenWidth * viewportFraction;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: SizedBox(
                            width: itemWidth,
                            height: cardHeight,
                            child: _FormationCard(
                              formation: formations[index],
                              cardWidth: itemWidth,
                              cardHeight: cardHeight,
                              showDescription:
                                  isWide ||
                                  (screenWidth > 480 &&
                                      screenWidth > screenHeight),
                              onInscriptionSuccess:
                                  onInscriptionSuccess, // Passer le callback
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
      ],
    );
  }
}

class _FormationCard extends StatefulWidget {
  final Formation formation;
  final double cardWidth;
  final double cardHeight;
  final bool showDescription;
  final Function(String message, String formationTitle)?
  onInscriptionSuccess; // Nouveau callback

  const _FormationCard({
    required this.formation,
    required this.cardWidth,
    required this.cardHeight,
    this.showDescription = false,
    this.onInscriptionSuccess, // Ajout du callback
  });

  @override
  State<_FormationCard> createState() => _FormationCardState();
}

class _FormationCardState extends State<_FormationCard> {
  late final FormationRepository _repository;
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
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(
      widget.formation.category.categorie,
    );
    final theme = Theme.of(context);
    final imageHeight = math.min(
      math.max(widget.cardHeight * 0.28, 80.0),
      140.0,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToDetail(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header avec image circulaire
              Container(
                height: imageHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Container(
                    width: imageHeight * 0.7,
                    height: imageHeight * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child:
                          widget.formation.imageUrl != null
                              ? CachedNetworkImage(
                                imageUrl:
                                    '${AppConstants.baseUrlImg}/${widget.formation.imageUrl}',
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Center(
                                      child: Icon(
                                        Icons.school,
                                        color: categoryColor,
                                        size: 30,
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Center(
                                      child: Icon(
                                        Icons.school,
                                        color: categoryColor,
                                        size: 30,
                                      ),
                                    ),
                              )
                              : Center(
                                child: Icon(
                                  Icons.school,
                                  color: categoryColor,
                                  size: 30,
                                ),
                              ),
                    ),
                  ),
                ),
              ),

              // Contenu de la carte
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Titre et catégorie
                      Column(
                        children: [
                          Text(
                            widget.formation.titre,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.formation.category.categorie,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Optional description on wide/tablet/landscape
                      if (widget.showDescription &&
                          widget.formation.description.isNotEmpty)
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Html(
                              data: widget.formation.description,
                              style: {
                                '*': Style(
                                  maxLines: widget.cardWidth < 5 ? 2 : 3,
                                  textOverflow: TextOverflow.ellipsis,
                                  color: Colors.black87,
                                  fontSize: FontSize(
                                    theme.textTheme.bodySmall?.fontSize ?? 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              },
                            ),
                          ),
                        ),

                      // Spacer pour pousser le contenu vers le bas
                      const Spacer(),

                      // Durée et prix
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: theme.hintColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.formation.duree} H',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            ('${formatPrice(widget.formation.tarif.toInt())} €'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Boutons d'action
                      Row(
                        children: [
                          if (widget.formation.cursusPdf != null)
                            Expanded(
                              child: _buildPdfButton(context, categoryColor),
                            ),
                          if (widget.formation.cursusPdf != null)
                            const SizedBox(width: 8),
                          Expanded(
                            child: _buildRegisterButton(context, categoryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context, Color color) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _registerToFormation(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child:
            _isLoading
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  _success
                      ? "Inscrit"
                      : _error
                      ? "Erreur"
                      : "S'inscrire",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }

  Widget _buildPdfButton(BuildContext context, Color color) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: () => _openPdf(context),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              'PDF',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FormationDetailPage(formationId: widget.formation.id),
      ),
    );
  }

  Future<void> _registerToFormation(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _success = false;
      _error = false;
    });
    try {
      await _repository.inscrireAFormation(widget.formation.id);
      setState(() {
        _success = true;
      });

      // Appeler le callback de succès si fourni
      if (widget.onInscriptionSuccess != null) {
        widget.onInscriptionSuccess!(
          'Un mail de confirmation vous a été envoyé, votre conseiller va bientôt prendre contact avec vous.',
          widget.formation.titre,
        );
      } else {
        // Fallback: afficher le SnackBar si pas de callback
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Inscription réussie !')));
      }
    } catch (e) {
      setState(() {
        _error = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'inscription. Veuillez réessayer.'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openPdf(BuildContext context) async {
    final pdfUrl = '${AppConstants.baseUrlImg}/${widget.formation.cursusPdf}';
    try {
      if (await canLaunch(pdfUrl)) {
        await launch(pdfUrl);
      } else {
        throw 'Impossible d\'ouvrir le PDF';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
      case 'IA':
        return const Color(0xFFABDA96);
      default:
        return Colors.grey;
    }
  }
}
