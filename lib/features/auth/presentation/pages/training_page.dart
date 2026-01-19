import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/formation_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/formation_repository.dart';
import 'package:wizi_learn/features/auth/presentation/pages/detail_formation_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/help_dialog.dart';
import 'package:share_plus/share_plus.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

enum SortOption {
  nameAsc,
  nameDesc,
  durationAsc,
  durationDesc,
}

class _TrainingPageState extends State<TrainingPage> {
  late final FormationRepository _repository;
  late Future<List<Formation>> _futureFormations;
  String? _selectedCategory;
  SortOption _selectedSort = SortOption.nameAsc;
  int _currentPage = 1;
  final int _itemsPerPage = 6;
  bool _isLoadingMore = false;

  // Map des icônes pour chaque catégorie
  final Map<String, IconData> _categoryIcons = {
    'Bureautique': Icons.computer,
    'Langues': Icons.language,
    'Internet': Icons.public,
    'Création': Icons.brush,
    'IA': Icons.smart_toy,
  };

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _repository = FormationRepository(apiClient: apiClient);
    _futureFormations = _repository.getFormations();
  }

  // Fonction pour trier les formations
  List<Formation> _sortFormations(List<Formation> formations) {
    switch (_selectedSort) {
      case SortOption.nameAsc:
        formations.sort((a, b) => a.titre.compareTo(b.titre));
        break;
      case SortOption.nameDesc:
        formations.sort((a, b) => b.titre.compareTo(a.titre));
        break;
      case SortOption.durationAsc:
        formations.sort((a, b) => a.duree.compareTo(b.duree));
        break;
      case SortOption.durationDesc:
        formations.sort((a, b) => b.duree.compareTo(a.duree));
        break;
    }
    return formations;
  }

  // Fonction pour paginer les formations
  List<Formation> _paginateFormations(List<Formation> formations) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return formations.sublist(
      0,
      endIndex > formations.length ? formations.length : endIndex,
    );
  }

  // Charger plus d'éléments
  void _loadMore() {
    if (!_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _isLoadingMore = false;
        });
      });
    }
  }

  // Réinitialiser la pagination
  void _resetPagination() {
    setState(() {
      _currentPage = 1;
    });
  }

  /// Partage une formation avec détails riches
  void _shareFormation(Formation formation) {
    final cleanDescription = formation.description
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();

    final truncatedDescription = cleanDescription.length > 200
        ? '${cleanDescription.substring(0, 200)}...'
        : cleanDescription;

    String? cleanObjectives;
    if (formation.objectifs != null && formation.objectifs!.isNotEmpty) {
      cleanObjectives = formation.objectifs!
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();
      if (cleanObjectives.length > 150) {
        cleanObjectives = '${cleanObjectives.substring(0, 150)}...';
      }
    }

    String pdfLink = '';
    if (formation.cursusPdfUrl != null && formation.cursusPdfUrl!.isNotEmpty) {
      pdfLink = formation.cursusPdfUrl!;
    } else if (formation.cursusPdf != null && formation.cursusPdf!.isNotEmpty) {
      pdfLink = AppConstants.getMediaUrl(formation.cursusPdf!);
    }

    String text = '🎓 *Formation : ${formation.titre}*\n\n';
    text += '📝 *Description :*\n$truncatedDescription\n\n';

    if (cleanObjectives != null && cleanObjectives.isNotEmpty) {
      text += '🎯 *Objectifs :*\n$cleanObjectives\n\n';
    }

    if (pdfLink.isNotEmpty) {
      text += '📄 *Programme complet (PDF) :*\n$pdfLink\n\n';
    }

    text += '🔗 *Lien vers la formation :*\nhttps://wizi-learn.com/catalogue-formation/${formation.id}';

    Share.share(text, subject: formation.titre);
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: isLandscape
          ? null // Masquer l'AppBar en mode paysage pour gagner de la place
          : AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Notre catalogue de formations',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline,
              color: Colors.black87,
              size: 24,
            ),
            tooltip: 'Voir le tutoriel',
            onPressed: () => showStandardHelpDialog(
              context,
              steps: const [
                'Sélectionnez une catégorie en haut.',
                'Utilisez les filtres pour trier les formations.',
                'Parcourez les formations avec la pagination.',
                'Touchez une formation pour voir les détails.',
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: FutureBuilder<List<Formation>>(
        future: _futureFormations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(isLandscape);
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString(), isLandscape);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(isLandscape);
          }

          final formations = snapshot.data!;
          final categories = _getUniqueCategories(formations);

          if (_selectedCategory == null && categories.isNotEmpty) {
            _selectedCategory = categories.first;
          }

          // En mode paysage, on utilise un layout plus compact
          if (isLandscape) {
            return _buildLandscapeLayout(formations, categories, screenHeight);
          }

          return _buildPortraitLayout(formations, categories);
        },
      ),
    );
  }

  Widget _buildLandscapeLayout(
      List<Formation> formations, List<String> categories, double screenHeight) {
    return Column(
      children: [
        // En-tête compact pour le paysage - TOUTE LA LIGNE EN HAUT
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              // Titre compact
              Text(
                'Formations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),

              // Compteur et pagination SUR LA MÊME LIGNE
              _buildLandscapeCounterAndPagination(formations),

              const SizedBox(width: 8),

              // Menu de tri compact
              PopupMenuButton<SortOption>(
                icon: Icon(Icons.sort, color: Colors.grey.shade700, size: 18),
                onSelected: (SortOption value) {
                  setState(() {
                    _selectedSort = value;
                    _resetPagination();
                  });
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(value: SortOption.nameAsc, child: Text('Nom (A-Z)')),
                  const PopupMenuItem(value: SortOption.nameDesc, child: Text('Nom (Z-A)')),
                  const PopupMenuItem(value: SortOption.durationAsc, child: Text('Durée (Croissante)')),
                  const PopupMenuItem(value: SortOption.durationDesc, child: Text('Durée (Décroissante)')),
                ],
              ),

              const SizedBox(width: 4),

              // Bouton aide
              IconButton(
                icon: Icon(Icons.help_outline, size: 18, color: Colors.black87),
                onPressed: () => showStandardHelpDialog(
                  context,
                  steps: const [
                    'Sélectionnez une catégorie en haut.',
                    'Utilisez les filtres pour trier les formations.',
                    'Parcourez les formations avec la pagination.',
                    'Touchez une formation pour voir les détails.',
                  ],
                ),
              ),
            ],
          ),
        ),

        // Section catégories compacte
        _buildCompactCategorySection(categories),

        // Liste des formations avec hauteur adaptative
        Expanded(
          child: _buildCompactFormationsList(formations, screenHeight),
        ),
      ],
    );
  }

  String _getShortCategoryName(String category) {
    switch (category) {
      case 'Bureautique':
        return 'Bureau';
      case 'Langues':
        return 'Langues';
      case 'Internet':
        return 'Web';
      case 'Création':
        return 'Créa';
      case 'IA':
        return 'IA';
      default:
        return category.length > 6 ? category.substring(0, 6) : category;
    }
  }
  Widget _buildLandscapeCounterAndPagination(List<Formation> formations) {
    final categoryFormations = formations
        .where((formation) => formation.category.categorie == _selectedCategory)
        .toList();
    final sortedFormations = _sortFormations(categoryFormations);
    final totalItems = sortedFormations.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final displayedItems = _paginateFormations(sortedFormations);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compteur compact
        Text(
          '${displayedItems.length}/$totalItems',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),

        // Pagination compacte
        if (totalPages > 1) ...[
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  size: 16,
                  color: _currentPage > 1 ? Colors.blue : Colors.grey.shade400,
                ),
                onPressed: _currentPage > 1
                    ? () {
                  setState(() {
                    _currentPage--;
                  });
                }
                    : null,
              ),
              Text(
                '$_currentPage/$totalPages',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: _currentPage < totalPages ? Colors.blue : Colors.grey.shade400,
                ),
                onPressed: _currentPage < totalPages
                    ? () {
                  setState(() {
                    _currentPage++;
                  });
                }
                    : null,
              ),
            ],
          ),
        ],
      ],
    );
  }
  Widget _buildCompactCategorySection(List<String> categories) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 2)],
      ),
      child: SizedBox(
        height: 50, // Hauteur encore plus réduite
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = _selectedCategory == category;
            final categoryColor = _getCategoryColor(category);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                  _resetPagination();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 55, // Largeur réduite
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                    colors: [categoryColor, categoryColor.withOpacity(0.8)],
                  )
                      : null,
                  color: isSelected ? null : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? categoryColor : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _categoryIcons[category] ?? Icons.category,
                      size: 16, // Icône plus petite
                      color: isSelected ? Colors.white : categoryColor,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getShortCategoryName(category),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey.shade800,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  Widget _buildPortraitLayout(List<Formation> formations, List<String> categories) {
    return Column(
      children: [
        // Section Catégories normale
        _buildCategorySection(categories, false),

        // Section Filtres et informations
        _buildFilterSection(formations, false),

        // Liste des formations
        _buildFormationsList(formations, false),
      ],
    );
  }




  Widget _buildCompactFormationsList(List<Formation> formations, double screenHeight) {
    final categoryFormations = formations
        .where((formation) => formation.category.categorie == _selectedCategory)
        .toList();
    final sortedFormations = _sortFormations(categoryFormations);
    final displayedFormations = _paginateFormations(sortedFormations);
    final hasMore = displayedFormations.length < sortedFormations.length;

    if (_selectedCategory == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez une catégorie',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (displayedFormations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Aucune formation dans cette catégorie',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: displayedFormations.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == displayedFormations.length && hasMore) {
          return _buildCompactLoadMoreButton();
        }
        final formation = displayedFormations[index];
        return _buildCompactFormationCard(context, formation);
      },
    );
  }

  Widget _buildCompactFormationCard(BuildContext context, Formation formation) {
    final categoryColor = _getCategoryColor(formation.category.categorie);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FormationDetailPage(formationId: formation.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Image compacte
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      categoryColor.withOpacity(0.1),
                      categoryColor.withOpacity(0.3),
                    ],
                  ),
                  border: Border.all(color: categoryColor.withOpacity(0.3), width: 1),
                ),
                child: ClipOval(
                  child: formation.imageUrl != null
                      ? CachedNetworkImage(
                    imageUrl: AppConstants.getMediaUrl(formation.imageUrl),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: Icon(
                        _categoryIcons[formation.category.categorie] ?? Icons.school,
                        color: categoryColor,
                        size: 14,
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        _categoryIcons[formation.category.categorie] ?? Icons.school,
                        color: categoryColor,
                        size: 14,
                      ),
                    ),
                  )
                      : Center(
                    child: Icon(
                      _categoryIcons[formation.category.categorie] ?? Icons.school,
                      color: categoryColor,
                      size: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Contenu compact
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formation.titre,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formation.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Métadonnées compactes
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 9, color: Colors.grey.shade600),
                        const SizedBox(width: 2),
                        Text(
                          '${formation.duree}h',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator(strokeWidth: 2)
            : ElevatedButton(
          onPressed: _loadMore,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          ),
          child: const Text(
            'Charger plus',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }  Widget _buildLoadingState(bool isLandscape) {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement en cours...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, bool isLandscape) {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Une erreur est survenue',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _futureFormations = _repository.getFormations();
                  });
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isLandscape) {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune formation disponible',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(List<String> categories, bool isLandscape) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isLandscape ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: isLandscape ? 70 : 90, // Hauteur réduite en paysage
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: isLandscape ? 12 : 16),
          itemCount: categories.length,
          separatorBuilder: (_, __) => SizedBox(width: isLandscape ? 8 : 12),
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = _selectedCategory == category;
            final categoryColor = _getCategoryColor(category);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                  _resetPagination();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isLandscape ? 70 : 80, // Largeur réduite en paysage
                decoration: BoxDecoration(
                  gradient:
                      isSelected
                          ? LinearGradient(
                            colors: [
                              categoryColor,
                              categoryColor.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                          : null,
                  color: isSelected ? null : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? categoryColor : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: categoryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _categoryIcons[category] ?? Icons.category,
                      size: isLandscape ? 20 : 24, // Icône plus petite
                      color: isSelected ? Colors.white : categoryColor,
                    ),
                    SizedBox(height: isLandscape ? 6 : 8),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: isLandscape ? 10 : 11, // Texte plus petit
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey.shade800,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterSection(List<Formation> formations, bool isLandscape) {
    final categoryFormations =
        formations
            .where(
              (formation) => formation.category.categorie == _selectedCategory,
            )
            .toList();
    final sortedFormations = _sortFormations(categoryFormations);
    final totalItems = sortedFormations.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final displayedItems = _paginateFormations(sortedFormations);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 12 : 16,
        vertical: isLandscape ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Compteur de formations avec texte adaptatif
          RichText(
            text: TextSpan(
              text: '${displayedItems.length} ',
              style: TextStyle(
                fontSize: isLandscape ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              children: [
                TextSpan(
                  text: 'sur $totalItems formations',
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Colors.grey.shade600,
                    fontSize: isLandscape ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Pagination
          if (totalPages > 1) ...[
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    size: isLandscape ? 20 : 24,
                    color:
                        _currentPage > 1 ? Colors.blue : Colors.grey.shade400,
                  ),
                  onPressed:
                      _currentPage > 1
                          ? () {
                            setState(() {
                              _currentPage--;
                            });
                          }
                          : null,
                ),
                Text(
                  '$_currentPage/$totalPages',
                  style: TextStyle(
                    fontSize: isLandscape ? 12 : 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    size: isLandscape ? 20 : 24,
                    color:
                        _currentPage < totalPages
                            ? Colors.blue
                            : Colors.grey.shade400,
                  ),
                  onPressed:
                      _currentPage < totalPages
                          ? () {
                            setState(() {
                              _currentPage++;
                            });
                          }
                          : null,
                ),
              ],
            ),
            SizedBox(width: isLandscape ? 12 : 16),
          ],

          // Menu de tri
          PopupMenuButton<SortOption>(
            icon: Icon(
              Icons.sort,
              color: Colors.grey.shade700,
              size: isLandscape ? 20 : 24,
            ),
            onSelected: (SortOption value) {
              setState(() {
                _selectedSort = value;
                _resetPagination();
              });
            },
            itemBuilder:
                (BuildContext context) => [
                  const PopupMenuItem(
                    value: SortOption.nameAsc,
                    child: Text('Nom (A-Z)'),
                  ),
                  const PopupMenuItem(
                    value: SortOption.nameDesc,
                    child: Text('Nom (Z-A)'),
                  ),
                  const PopupMenuItem(
                    value: SortOption.nameDesc,
                    child: Text('Nom (Z-A)'),
                  ),
                  const PopupMenuItem(
                    value: SortOption.durationAsc,
                    child: Text('Durée (Croissante)'),
                  ),
                  const PopupMenuItem(
                    value: SortOption.durationDesc,
                    child: Text('Durée (Décroissante)'),
                  ),
                ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormationsList(List<Formation> formations, bool isLandscape) {
    final categoryFormations =
        formations
            .where(
              (formation) => formation.category.categorie == _selectedCategory,
            )
            .toList();
    final sortedFormations = _sortFormations(categoryFormations);
    final displayedFormations = _paginateFormations(sortedFormations);
    final hasMore = displayedFormations.length < sortedFormations.length;

    if (_selectedCategory == null) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Sélectionnez une catégorie',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    if (displayedFormations.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Aucune formation dans cette catégorie',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        children: [
          // Liste des formations
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                // Calcul dynamique adapté à l'orientation
                final crossAxisCount =
                    isLandscape
                        ? (width / 350).floor().clamp(
                          2,
                          4,
                        ) // Plus de colonnes en paysage
                        : (width / 400).floor().clamp(1, 2);

                // Utiliser GridView uniquement si l'écran est assez large
                final useGridView = width > 600;

                if (!useGridView) {
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      isLandscape ? 12 : 16,
                      8,
                      isLandscape ? 12 : 16,
                      isLandscape ? 12 : 16,
                    ),
                    itemCount: displayedFormations.length + (hasMore ? 1 : 0),
                    separatorBuilder:
                        (_, __) => SizedBox(height: isLandscape ? 8 : 12),
                    itemBuilder: (context, index) {
                      if (index == displayedFormations.length && hasMore) {
                        return _buildLoadMoreButton(isLandscape);
                      }
                      final formation = displayedFormations[index];
                      return _buildFormationCard(
                        context,
                        formation,
                        false,
                        isLandscape,
                      );
                    },
                  );
                }

                return GridView.builder(
                  padding: EdgeInsets.fromLTRB(
                    isLandscape ? 12 : 16,
                    8,
                    isLandscape ? 12 : 16,
                    isLandscape ? 12 : 16,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: isLandscape ? 12 : 16,
                    mainAxisSpacing: isLandscape ? 12 : 16,
                    childAspectRatio:
                        isLandscape ? 1.4 : 1.6, // Aspect ratio adaptatif
                  ),
                  itemCount: displayedFormations.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == displayedFormations.length && hasMore) {
                      return _buildLoadMoreButton(isLandscape);
                    }
                    final formation = displayedFormations[index];
                    return _buildFormationCard(
                      context,
                      formation,
                      true,
                      isLandscape,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton(bool isLandscape) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isLandscape ? 12 : 16),
      child: Center(
        child:
            _isLoadingMore
                ? const CircularProgressIndicator(strokeWidth: 2)
                : ElevatedButton(
                  onPressed: _loadMore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 24 : 32,
                      vertical: isLandscape ? 10 : 12,
                    ),
                  ),
                  child: Text(
                    'Charger plus de formations',
                    style: TextStyle(fontSize: isLandscape ? 14 : 16),
                  ),
                ),
      ),
    );
  }

  Widget _buildFormationCard(
    BuildContext context,
    Formation formation,
    bool isGrid,
    bool isLandscape,
  ) {
    final categoryColor = _getCategoryColor(formation.category.categorie);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: isLandscape ? const EdgeInsets.all(4) : const EdgeInsets.all(0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => FormationDetailPage(formationId: formation.id),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(isLandscape ? 12 : 16),
          child:
              isGrid
                  ? _buildGridLayout(formation, categoryColor, isLandscape)
                  : _buildListLayout(formation, categoryColor, isLandscape),
        ),
      ),
    );
  }

  Widget _buildListLayout(
    Formation formation,
    Color categoryColor,
    bool isLandscape,
  ) {
    return Row(
      children: [
        // Image avec taille adaptative
        Container(
          width: isLandscape ? 60 : 80,
          height: isLandscape ? 60 : 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                categoryColor.withOpacity(0.1),
                categoryColor.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: categoryColor.withOpacity(0.3), width: 2),
          ),
          child: ClipOval(
            child:
                formation.imageUrl != null
                    ? CachedNetworkImage(
                      imageUrl:
                          AppConstants.getMediaUrl(formation.imageUrl),
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Center(
                            child: Icon(
                              _categoryIcons[formation.category.categorie] ??
                                  Icons.school,
                              color: categoryColor,
                              size: isLandscape ? 24 : 32,
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Center(
                            child: Icon(
                              _categoryIcons[formation.category.categorie] ??
                                  Icons.school,
                              color: categoryColor,
                              size: isLandscape ? 24 : 32,
                            ),
                          ),
                    )
                    : Center(
                      child: Icon(
                        _categoryIcons[formation.category.categorie] ??
                            Icons.school,
                        color: categoryColor,
                        size: isLandscape ? 24 : 32,
                      ),
                    ),
          ),
        ),
        SizedBox(width: isLandscape ? 12 : 16),

        // Contenu avec texte adaptatif
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formation.titre.toUpperCase(),
                style: TextStyle(
                  fontSize: isLandscape ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isLandscape ? 4 : 6),
              Text(
                formation.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                style: TextStyle(
                  fontSize: isLandscape ? 12 : 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isLandscape ? 8 : 12),
              Row(
                children: [
                  // Durée
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 6 : 8,
                      vertical: isLandscape ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: isLandscape ? 12 : 14,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: isLandscape ? 3 : 4),
                        Text(
                          '${formation.duree}h',
                          style: TextStyle(
                            fontSize: isLandscape ? 11 : 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.share_outlined,
                      size: isLandscape ? 18 : 20,
                      color: categoryColor,
                    ),
                    onPressed: () => _shareFormation(formation),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridLayout(
    Formation formation,
    Color categoryColor,
    bool isLandscape,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec image et titre
        Row(
          children: [
            Container(
              width: isLandscape ? 50 : 60,
              height: isLandscape ? 50 : 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    categoryColor.withOpacity(0.1),
                    categoryColor.withOpacity(0.3),
                  ],
                ),
                border: Border.all(
                  color: categoryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child:
                    formation.imageUrl != null
                        ? CachedNetworkImage(
                          imageUrl:
                              AppConstants.getMediaUrl(formation.imageUrl),
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Center(
                                child: Icon(
                                  _categoryIcons[formation
                                          .category
                                          .categorie] ??
                                      Icons.school,
                                  color: categoryColor,
                                  size: isLandscape ? 20 : 24,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Center(
                                child: Icon(
                                  _categoryIcons[formation
                                          .category
                                          .categorie] ??
                                      Icons.school,
                                  color: categoryColor,
                                  size: isLandscape ? 20 : 24,
                                ),
                              ),
                        )
                        : Center(
                          child: Icon(
                            _categoryIcons[formation.category.categorie] ??
                                Icons.school,
                            color: categoryColor,
                            size: isLandscape ? 20 : 24,
                          ),
                        ),
              ),
            ),
            SizedBox(width: isLandscape ? 8 : 12),
            Expanded(
              child: Text(
                formation.titre,
                style: TextStyle(
                  fontSize: isLandscape ? 13 : 15,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: isLandscape ? 8 : 12),

        // Description
        Expanded(
          child: Text(
            formation.description.replaceAll(RegExp(r'<[^>]*>'), ''),
            style: TextStyle(
              fontSize: isLandscape ? 11 : 12,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
            maxLines: isLandscape ? 2 : 3, // Moins de lignes en paysage
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: isLandscape ? 8 : 12),

        // Pied de carte
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 6 : 8,
                vertical: isLandscape ? 3 : 4,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: isLandscape ? 10 : 12,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: isLandscape ? 3 : 4),
                  Text(
                    '${formation.duree}h',
                    style: TextStyle(
                      fontSize: isLandscape ? 10 : 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                Icons.share_outlined,
                size: isLandscape ? 16 : 18,
                color: categoryColor,
              ),
              onPressed: () => _shareFormation(formation),
            ),
          ],
        ),
      ],
    );
  }

  List<String> _getUniqueCategories(List<Formation> formations) {
    return formations.map((f) => f.category.categorie).toSet().toList();
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


