import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/features/auth/data/models/formation_model.dart';
import 'package:wizi_learn/features/auth/presentation/pages/detail_formation_page.dart';

class RandomFormationsWidget extends StatelessWidget {
  final List<Formation> formations;
  final VoidCallback? onRefresh;

  const RandomFormationsWidget({
    super.key,
    required this.formations,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    double clamp(double value, double min, double max) =>
        value < min ? min : (value > max ? max : value);

    // Largeur de carte fluide avec limites
    final cardWidth = clamp(screenWidth * 0.44, 140, 220);
    final cardHeight = cardWidth * 1.4;
    final headerFontSize = clamp(screenWidth * 0.045, 15, 22);
    final iconSize = clamp(screenWidth * 0.06, 18, 28);
    final refreshIconSize = clamp(screenWidth * 0.055, 18, 26);
    final listPadding = clamp(screenWidth * 0.02, 6, 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header avec bouton refresh
        _buildHeader(context, headerFontSize, refreshIconSize),

        // Liste horizontale des formations
        SizedBox(
          height: cardHeight, // Hauteur proportionnelle à la largeur
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: listPadding),
            itemCount: formations.length,
            itemBuilder:
                (context, index) => ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: cardWidth,
                    maxWidth: cardWidth,
                  ),
                  child: _FormationCard(
                    formation: formations[index],
                    cardWidth: cardWidth,
                    iconSize: iconSize,
                    headerFontSize: headerFontSize,
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    double fontSize,
    double refreshIconSize,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Formations recommandées',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          if (onRefresh != null)
            IconButton(
              icon: Icon(Icons.refresh, size: refreshIconSize),
              onPressed: onRefresh,
              tooltip: 'Actualiser',
            ),
        ],
      ),
    );
  }
}

class _FormationCard extends StatelessWidget {
  final Formation formation;
  final double cardWidth;
  final double iconSize;
  final double headerFontSize;

  const _FormationCard({
    required this.formation,
    required this.cardWidth,
    required this.iconSize,
    required this.headerFontSize,
  });

  double clamp(double value, double min, double max) =>
      value < min ? min : (value > max ? max : value);

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(formation.category.categorie);
    final textTheme = Theme.of(context).textTheme;
    final imageHeight = cardWidth * 0.6;
    final badgeFontSize = clamp(cardWidth * 0.09, 9, 13);
    final titleFontSize = clamp(cardWidth * 0.11, 13, 18);
    final durationFontSize = clamp(cardWidth * 0.09, 10, 14);
    final priceFontSize = clamp(cardWidth * 0.12, 13, 18);
    final pdfFontSize = clamp(cardWidth * 0.09, 10, 14);
    final cardPadding = clamp(cardWidth * 0.07, 8, 16);
    final cardMargin = clamp(cardWidth * 0.03, 5, 12);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: cardMargin),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToDetail(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image avec placeholder
              _buildImageSection(imageHeight, categoryColor),

              // Contenu texte
              Padding(
                padding: EdgeInsets.all(cardPadding),
                child: SizedBox(
                  width:
                      cardWidth -
                      2 * cardPadding, // Largeur fixe déduisant le padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge catégorie
                      _buildCategoryBadge(categoryColor, badgeFontSize),

                      const SizedBox(height: 6),

                      // Titre avec hauteur fixe
                      SizedBox(
                        height: titleFontSize * 2.2, // Hauteur pour 2 lignes
                        child: Text(
                          formation.titre,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            fontSize: titleFontSize,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Durée et prix
                      _buildDurationAndPrice(
                        textTheme,
                        durationFontSize,
                        priceFontSize,
                      ),

                      // Bouton PDF si disponible
                      if (formation.cursusPdf != null)
                        _buildPdfButton(context, categoryColor, pdfFontSize),
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

  Widget _buildImageSection(double height, Color categoryColor) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: categoryColor.withOpacity(0.1),
        image:
            formation.imageUrl != null
                ? DecorationImage(
                  image: CachedNetworkImageProvider(
                    '${AppConstants.baseUrlImg}/${formation.imageUrl}',
                  ),
                  fit: BoxFit.cover,
                )
                : null,
      ),
      child:
          formation.imageUrl == null
              ? Center(
                child: Icon(
                  Icons.school,
                  color: categoryColor,
                  size: iconSize + 8,
                ),
              )
              : null,
    );
  }

  Widget _buildCategoryBadge(Color color, double fontSize) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        formation.category.categorie,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDurationAndPrice(
    TextTheme textTheme,
    double durationFontSize,
    double priceFontSize,
  ) {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: durationFontSize,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          '${formation.duree} H',
          style: textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade700,
            fontSize: durationFontSize,
          ),
        ),
        const Spacer(),
        Text(
          '${formation.tarif.toInt()} €',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade800,
            fontSize: priceFontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildPdfButton(BuildContext context, Color color, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: fontSize * 2.2,
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: Icon(Icons.picture_as_pdf, size: fontSize, color: color),
          label: Text(
            'PDF',
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            side: BorderSide(color: color),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          onPressed: () => _openPdf(context),
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormationDetailPage(formationId: formation.id),
      ),
    );
  }

  Future<void> _openPdf(BuildContext context) async {
    final pdfUrl = '${AppConstants.baseUrlImg}/${formation.cursusPdf}';
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
}
