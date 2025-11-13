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

// Nouvelle palette de couleurs harmonieuse
const Color kPrimaryBlue = Color(0xFF3D9BE9);
const Color kPrimaryBlueLight = Color(0xFFE8F4FE);
const Color kPrimaryBlueDark = Color(0xFF2A7BC8);

const Color kSuccessGreen = Color(0xFFABDA96);
const Color kSuccessGreenLight = Color(0xFFF0F9ED);
const Color kSuccessGreenDark = Color(0xFF7BBF5E);

const Color kAccentPurple = Color(0xFF9392BE);
const Color kAccentPurpleLight = Color(0xFFF5F4FF);
const Color kAccentPurpleDark = Color(0xFF6A6896);

const Color kWarningOrange = Color(0xFFFFC533);
const Color kWarningOrangeLight = Color(0xFFFFF8E8);
const Color kWarningOrangeDark = Color(0xFFE6A400);

const Color kErrorRed = Color(0xFFA55E6E);
const Color kErrorRedLight = Color(0xFFFBEAED);
const Color kErrorRedDark = Color(0xFF8C4454);

const Color kNeutralWhite = Colors.white;
const Color kNeutralGrey = Color(0xFFF8F9FA);
const Color kNeutralGreyDark = Color(0xFF6C757D);
const Color kNeutralBlack = Color(0xFF212529);

class RandomFormationsWidget extends StatelessWidget {
  final List<Formation> formations;
  final VoidCallback? onRefresh;
  final Function(String message, String formationTitle)? onInscriptionSuccess;

  const RandomFormationsWidget({
    super.key,
    required this.formations,
    this.onRefresh,
    this.onInscriptionSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        formations.isEmpty
            ? _buildEmptyState(context)
            : _buildFormationsCarousel(context, isWide),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kNeutralWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryBlue.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: 48,
            color: kNeutralGreyDark.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            "Aucune formation disponible",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: kNeutralGreyDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Revenez plus tard pour découvrir de nouvelles formations",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: kNeutralGreyDark.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormationsCarousel(BuildContext context, bool isWide) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double cardHeight;
    if (isWide) {
      cardHeight = screenHeight * 0.32;
      if (cardHeight < 320) cardHeight = 320;
      if (cardHeight > 520) cardHeight = 520;
    } else {
      cardHeight = screenHeight * 0.28;
      if (cardHeight < 260) cardHeight = 260;
      if (cardHeight > 380) cardHeight = 380;
    }

    final viewportFraction = isWide ? 0.42 : 0.68;
    final pageController = PageController(viewportFraction: viewportFraction);

    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: PageView.builder(
            controller: pageController,
            itemCount: formations.length,
            padEnds: true,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final itemWidth = screenWidth * viewportFraction;
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 12 : 8,
                  vertical: 8,
                ),
                child: _FormationCard(
                  formation: formations[index],
                  cardWidth: itemWidth,
                  cardHeight: cardHeight,
                  showDescription: isWide,
                  onInscriptionSuccess: onInscriptionSuccess,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Indicateurs de position
        // _buildPageIndicators(formations.length),
      ],
    );
  }

  Widget _buildPageIndicators(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                index == 0 ? kPrimaryBlue : kNeutralGreyDark.withOpacity(0.3),
          ),
        );
      }),
    );
  }
}

class _FormationCard extends StatefulWidget {
  final Formation formation;
  final double cardWidth;
  final double cardHeight;
  final bool showDescription;
  final Function(String message, String formationTitle)? onInscriptionSuccess;

  const _FormationCard({
    required this.formation,
    required this.cardWidth,
    required this.cardHeight,
    this.showDescription = false,
    this.onInscriptionSuccess,
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
      math.max(widget.cardHeight * 0.32, 90.0),
      150.0,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToDetail(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kNeutralWhite, kNeutralGrey.withOpacity(0.3)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec image et badge de catégorie
                Stack(
                  children: [
                    // Image de fond avec overlay
                    Container(
                      height: imageHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.15),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: imageHeight * 0.6,
                          height: imageHeight * 0.6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
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
                                              Icons.school_rounded,
                                              color: categoryColor,
                                              size: 32,
                                            ),
                                          ),
                                      errorWidget:
                                          (context, url, error) => Center(
                                            child: Icon(
                                              Icons.school_rounded,
                                              color: categoryColor,
                                              size: 32,
                                            ),
                                          ),
                                    )
                                    : Center(
                                      child: Icon(
                                        Icons.school_rounded,
                                        color: categoryColor,
                                        size: 32,
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    ),
                    // Badge de catégorie
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: categoryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.formation.category.categorie,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: kNeutralWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Contenu de la carte
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre
                        Text(
                          widget.formation.titre,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: kNeutralBlack,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Description (optionnelle)
                        if (widget.showDescription &&
                            widget.formation.description.isNotEmpty)
                          Expanded(
                            child: Html(
                              data: widget.formation.description,
                              style: {
                                '*': Style(
                                  maxLines: 3,
                                  textOverflow: TextOverflow.ellipsis,
                                  color: kNeutralGreyDark,
                                  fontSize: FontSize(
                                    theme.textTheme.bodySmall?.fontSize ?? 12,
                                  ),
                                  lineHeight: LineHeight(1.4),
                                  padding: HtmlPaddings.zero,
                                  margin: Margins.zero,
                                ),
                              },
                            ),
                          )
                        else
                          const Spacer(),

                        const SizedBox(height: 12),
                        // Boutons d'action
                        Row(
                          children: [
                            if (widget.formation.cursusPdf != null)
                              Expanded(
                                flex: 2,
                                child: _buildPdfButton(context, categoryColor),
                              ),
                            if (widget.formation.cursusPdf != null)
                              const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: _buildRegisterButton(
                                context,
                                categoryColor,
                              ),
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
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context, Color color) {
    final buttonState =
        _success
            ? _ButtonState.success
            : _error
            ? _ButtonState.error
            : _isLoading
            ? _ButtonState.loading
            : _ButtonState.normal;

    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _registerToFormation(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getButtonColor(buttonState, color),
          foregroundColor: kNeutralWhite,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
          shadowColor: color.withOpacity(0.3),
        ),
        child: _buildButtonContent(buttonState, context),
      ),
    );
  }

  Widget _buildButtonContent(_ButtonState state, BuildContext context) {
    switch (state) {
      case _ButtonState.loading:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: kNeutralWhite,
          ),
        );
      case _ButtonState.success:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, size: 16),
            const SizedBox(width: 6),
            Text(
              'Inscrit',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: kNeutralWhite,
              ),
            ),
          ],
        );
      case _ButtonState.error:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 16),
            const SizedBox(width: 6),
            Text(
              'Erreur',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: kNeutralWhite,
              ),
            ),
          ],
        );
      case _ButtonState.normal:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_rounded, size: 16),
            const SizedBox(width: 6),
            Text(
              'S\'inscrire',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: kNeutralWhite,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildPdfButton(BuildContext context, Color color) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: () => _openPdf(context),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: kNeutralWhite,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_rounded, size: 16, color: color),
            const SizedBox(width: 6),
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

  Color _getButtonColor(_ButtonState state, Color baseColor) {
    switch (state) {
      case _ButtonState.success:
        return kSuccessGreenDark;
      case _ButtonState.error:
        return kErrorRedDark;
      case _ButtonState.loading:
        return baseColor.withOpacity(0.7);
      case _ButtonState.normal:
        return baseColor;
    }
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

      if (widget.onInscriptionSuccess != null) {
        widget.onInscriptionSuccess!(
          'Un mail de confirmation vous a été envoyé, votre conseiller va bientôt prendre contact avec vous.',
          widget.formation.titre,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inscription à ${widget.formation.titre} réussie !'),
            backgroundColor: kSuccessGreenDark,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Erreur lors de l\'inscription. Veuillez réessayer.',
          ),
          backgroundColor: kErrorRedDark,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: kErrorRedDark),
      );
    }
  }

  String formatPrice(num price) {
    final formatter = NumberFormat("#,##0.##", "fr_FR");
    String formatted = formatter.format(price);
    formatted = formatted.replaceAll(RegExp(r'[\u202F\u00A0]'), ' ');
    return "$formatted €";
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Bureautique':
        return kPrimaryBlue;
      case 'Langues':
        return kErrorRed;
      case 'Internet':
        return kWarningOrange;
      case 'Création':
        return kAccentPurple;
      case 'IA':
        return kSuccessGreen;
      default:
        return kNeutralGreyDark;
    }
  }
}

enum _ButtonState { normal, loading, success, error }
