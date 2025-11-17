import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/formation_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/formation_repository.dart';
import 'package:wizi_learn/features/auth/presentation/pages/detail_formation_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/help_dialog.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

enum SortOption {
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
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

  // Options de tri

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
      case SortOption.priceAsc:
        formations.sort((a, b) => a.tarif.compareTo(b.tarif));
        break;
      case SortOption.priceDesc:
        formations.sort((a, b) => b.tarif.compareTo(a.tarif));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
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
            icon: const Icon(Icons.help_outline, color: Colors.black87),
            tooltip: 'Voir le tutoriel',
            onPressed:
                () => showStandardHelpDialog(
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
            return _buildLoadingState();
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final formations = snapshot.data!;
          final categories = _getUniqueCategories(formations);

          if (_selectedCategory == null && categories.isNotEmpty) {
            _selectedCategory = categories.first;
          }

          return Column(
            children: [
              // Section Catégories avec design amélioré
              _buildCategorySection(categories),

              // Section Filtres et informations
              _buildFilterSection(formations),

              // Liste des formations avec pagination
              _buildFormationsList(formations),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
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

  Widget _buildErrorState(String error) {
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

  Widget _buildEmptyState() {
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

  Widget _buildCategorySection(List<String> categories) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
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
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
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
                width: 80,
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
                      size: 24,
                      color: isSelected ? Colors.white : categoryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 11,
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

  Widget _buildFilterSection(List<Formation> formations) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Compteur de formations
          RichText(
            text: TextSpan(
              text: '${displayedItems.length} ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              children: [
                TextSpan(
                  text: 'sur $totalItems formations',
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Colors.grey.shade600,
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
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
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
            const SizedBox(width: 16),
          ],

          // Menu de tri
          PopupMenuButton<SortOption>(
            icon: Icon(Icons.sort, color: Colors.grey.shade700),
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
                    value: SortOption.priceAsc,
                    child: Text('Prix (Croissant)'),
                  ),
                  const PopupMenuItem(
                    value: SortOption.priceDesc,
                    child: Text('Prix (Décroissant)'),
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

  Widget _buildFormationsList(List<Formation> formations) {
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
                final isWide = width >= 800;
                final crossAxisCount = (width / 400).floor().clamp(1, 3);

                if (!isWide) {
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: displayedFormations.length + (hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == displayedFormations.length && hasMore) {
                        return _buildLoadMoreButton();
                      }
                      final formation = displayedFormations[index];
                      return _buildFormationCard(context, formation, false);
                    },
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: displayedFormations.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == displayedFormations.length && hasMore) {
                      return _buildLoadMoreButton();
                    }
                    final formation = displayedFormations[index];
                    return _buildFormationCard(context, formation, true);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Charger plus de formations'),
                ),
      ),
    );
  }

  Widget _buildFormationCard(
    BuildContext context,
    Formation formation,
    bool isGrid,
  ) {
    final categoryColor = _getCategoryColor(formation.category.categorie);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          padding: const EdgeInsets.all(16),
          child:
              isGrid
                  ? _buildGridLayout(formation, categoryColor)
                  : _buildListLayout(formation, categoryColor),
        ),
      ),
    );
  }

  Widget _buildListLayout(Formation formation, Color categoryColor) {
    return Row(
      children: [
        // Image avec effet moderne
        Container(
          width: 80,
          height: 80,
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
                          '${AppConstants.baseUrlImg}/${formation.imageUrl}',
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Center(
                            child: Icon(
                              _categoryIcons[formation.category.categorie] ??
                                  Icons.school,
                              color: categoryColor,
                              size: 32,
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Center(
                            child: Icon(
                              _categoryIcons[formation.category.categorie] ??
                                  Icons.school,
                              color: categoryColor,
                              size: 32,
                            ),
                          ),
                    )
                    : Center(
                      child: Icon(
                        _categoryIcons[formation.category.categorie] ??
                            Icons.school,
                        color: categoryColor,
                        size: 32,
                      ),
                    ),
          ),
        ),
        const SizedBox(width: 16),

        // Contenu
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formation.titre.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                formation.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Durée
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${formation.duree}h',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Prix
                  // Container(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 12,
                  //     vertical: 6,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     gradient: LinearGradient(
                  //       colors: [
                  //         Colors.orange.shade500,
                  //         Colors.orange.shade700,
                  //       ],
                  //       begin: Alignment.topLeft,
                  //       end: Alignment.bottomRight,
                  //     ),
                  //     borderRadius: BorderRadius.circular(12),
                  //   ),
                  //   child: Text(
                  //     '${formatPrice(formation.tarif.toInt())} €',
                  //     style: const TextStyle(
                  //       fontSize: 16,
                  //       fontWeight: FontWeight.bold,
                  //       color: Colors.white,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridLayout(Formation formation, Color categoryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec image et titre
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
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
                              '${AppConstants.baseUrlImg}/${formation.imageUrl}',
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Center(
                                child: Icon(
                                  _categoryIcons[formation
                                          .category
                                          .categorie] ??
                                      Icons.school,
                                  color: categoryColor,
                                  size: 24,
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
                                  size: 24,
                                ),
                              ),
                        )
                        : Center(
                          child: Icon(
                            _categoryIcons[formation.category.categorie] ??
                                Icons.school,
                            color: categoryColor,
                            size: 24,
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                formation.titre,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Description
        Expanded(
          child: Text(
            formation.description.replaceAll(RegExp(r'<[^>]*>'), ''),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 12),

        // Pied de carte
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${formation.duree}h',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            //   decoration: BoxDecoration(
            //     gradient: LinearGradient(
            //       colors: [Colors.orange.shade500, Colors.orange.shade700],
            //     ),
            //     borderRadius: BorderRadius.circular(10),
            //   ),
            // child: Text(
            //   '${formatPrice(formation.tarif.toInt())} €',
            //   style: const TextStyle(
            //     fontSize: 14,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.white,
            //   ),
            // ),
            // ),
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

String formatPrice(num price) {
  final formatter = NumberFormat("#,##0.##", "fr_FR");
  String formatted = formatter.format(price);
  formatted = formatted.replaceAll(RegExp(r'[\u202F\u00A0]'), ' ');
  formatted = formatted.replaceAll(' ', ' ');
  return formatted;
}
