import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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

  const RandomFormationsWidget({
    super.key,
    required this.formations,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 350;
    final cardWidth =
        isSmallScreen
            ? 180.0
            : (screenWidth < 450 ? 200.0 : screenWidth / 2.75);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header avec bouton refresh
        _buildHeader(context, isSmallScreen),

        // Liste horizontale des formations
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
              height:
                  screenWidth < 768
                      ? cardWidth * 1.3
                      : (screenWidth < 1024 ? cardWidth * 1 : cardWidth * 0.95),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
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
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
              ),
            ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        // children: [
        //   Text(
        //     'Formations recommandées',
        //     style: TextStyle(
        //       fontSize: isSmallScreen ? 16 : 18,
        //       fontWeight: FontWeight.bold,
        //       color: Theme.of(context).primaryColor,
        //     ),
        //   ),
        // ],
      ),
    );
  }
}

class _FormationCard extends StatefulWidget {
  final Formation formation;
  final double cardWidth;
  final bool isSmallScreen;

  const _FormationCard({
    required this.formation,
    required this.cardWidth,
    this.isSmallScreen = false,
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
    final textTheme = Theme.of(context).textTheme;
    final imageHeight = widget.cardWidth * 0.55;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToDetail(context),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSection(imageHeight, categoryColor),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      child: SizedBox(
                        width: widget.cardWidth - 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCategoryBadge(categoryColor, textTheme),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 30,
                              child: Text(
                                widget.formation.titre.toUpperCase(),
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildDurationAndPrice(textTheme),
                            const SizedBox(height: 6),
                            _buildActionButtons(
                              context,
                              categoryColor,
                              textTheme,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
            widget.formation.imageUrl != null
                ? DecorationImage(
                  image: CachedNetworkImageProvider(
                    '${AppConstants.baseUrlImg}/${widget.formation.imageUrl}',
                  ),
                  fit: BoxFit.cover,
                )
                : null,
      ),
      child:
          widget.formation.imageUrl == null
              ? Center(
                child: Icon(Icons.school, color: categoryColor, size: 36),
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
        widget.formation.category.categorie,
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
          '${widget.formation.duree} H',
          style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
        ),
        const Spacer(),
        Text(
          '${widget.formation.tarif.toInt()} €',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Color color,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        if (widget.formation.cursusPdf != null)
          Expanded(child: _buildPdfButton(context, color, textTheme)),
        if (widget.formation.cursusPdf != null) const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _registerToFormation(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding:
                  widget.isSmallScreen
                      ? const EdgeInsets.symmetric(vertical: 2, horizontal: 0)
                      : const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
              minimumSize:
                  widget.isSmallScreen ? const Size(0, 28) : const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
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
                          ? "Inscription réussie !"
                          : _error
                          ? "Erreur, réessayer"
                          : "S'inscrire",
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: widget.isSmallScreen ? 10 : null,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfButton(
    BuildContext context,
    Color color,
    TextTheme textTheme,
  ) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: () => _openPdf(context),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inscription réussie !')));
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
