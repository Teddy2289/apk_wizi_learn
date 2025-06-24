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
    final isSmallScreen = screenWidth < 350;
    final cardWidth = isSmallScreen
      ? 180.0
      : (screenWidth < 450
        ? 200.0
        : screenWidth / 2.75);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header avec bouton refresh
        _buildHeader(context, isSmallScreen),

        // Liste horizontale des formations
        SizedBox(
            height: screenWidth < 768 ? cardWidth * 1.3 : (screenWidth < 1024 ? cardWidth * 1 :cardWidth*0.95), // Hauteur ajustée pour petits écrans
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: formations.length,
            itemBuilder: (context, index) => ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: cardWidth,
                maxWidth: cardWidth,
              ),
              child: _FormationCard(
                formation: formations[index],
                cardWidth: cardWidth,
                isSmallScreen: isSmallScreen, // Pass down
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Formations recommandées',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          if (onRefresh != null)
            IconButton(
              icon: Icon(Icons.refresh, size: isSmallScreen ? 20 : 24),
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
  final bool isSmallScreen;

  const _FormationCard({
    required this.formation,
    required this.cardWidth,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(formation.category.categorie);
    final textTheme = Theme.of(context).textTheme;
    final imageHeight = cardWidth * 0.55;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),  // Bordures légèrement réduites
        ),
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
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: SizedBox(
                  width: cardWidth - 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge catégorie
                      _buildCategoryBadge(categoryColor, textTheme),
                      const SizedBox(height: 4),
                      // Titre avec hauteur fixe
                      SizedBox(
                        height: 30,
                        child: Text(
                          formation.titre.toUpperCase(),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Durée et prix
                      _buildDurationAndPrice(textTheme),

                      const SizedBox(height: 6),

                      // Boutons en ligne
                      _buildActionButtons(context, categoryColor, textTheme),
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
        image: formation.imageUrl != null
            ? DecorationImage(
          image: CachedNetworkImageProvider(
              '${AppConstants.baseUrlImg}/${formation.imageUrl}'),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: formation.imageUrl == null
          ? Center(
        child: Icon(
          Icons.school,
          color: categoryColor,
          size: 36,
        ),
      )
          : null,
    );
  }

  Widget _buildCategoryBadge(Color color, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        formation.category.categorie,
        style: textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDurationAndPrice(TextTheme textTheme) {
    return Row(
      children: [
        Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          '${formation.duree} H',
          style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
        ),
        const Spacer(),
        Text(
          '${formation.tarif.toInt()} €',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Color color, TextTheme textTheme) {
    return Row(
      children: [
        // Bouton PDF si disponible
        if (formation.cursusPdf != null)
          Expanded(
            child: _buildPdfButton(context, color, textTheme),
          ),

        if (formation.cursusPdf != null) const SizedBox(width: 8),

        // Bouton S'inscrire
        Expanded(
          child: ElevatedButton(
            onPressed: () => _registerToFormation(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: isSmallScreen
                  ? const EdgeInsets.symmetric(vertical: 2, horizontal: 0)
                  : const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
              minimumSize: isSmallScreen ? const Size(0, 28) : const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
            ),
            child: Text(
              'S\'inscrire',
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: isSmallScreen ? 10 : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfButton(BuildContext context, Color color, TextTheme textTheme) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: () => _openPdf(context),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              'PDF',
              style: textTheme.labelSmall?.copyWith(
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
        builder: (context) => FormationDetailPage(formationId: formation.id),
      ),
    );
  }

  void _registerToFormation(BuildContext context) {
    // TODO: Implémenter la logique d'inscription
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Inscription à ${formation.titre}'),
        backgroundColor: Colors.green,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Bureautique': return const Color(0xFF3D9BE9);
      case 'Langues': return const Color(0xFFA55E6E);
      case 'Internet': return const Color(0xFFFFC533);
      case 'Création': return const Color(0xFF9392BE);
      default: return Colors.grey;
    }
  }
}