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

class _TrainingPageState extends State<TrainingPage> {
  late final FormationRepository _repository;
  late Future<List<Formation>> _futureFormations;
  String? _selectedCategory;

  // Map des icônes pour chaque catégorie
  final Map<String, IconData> _categoryIcons = {
    'Bureautique': Icons.computer,
    'Langues': Icons.language,
    'Internet': Icons.public,
    'Création': Icons.brush,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    '1. Sélectionnez une catégorie en haut.',
                    '2. Parcourez les formations de la catégorie.',
                    '3. Touchez une formation pour voir les détails.',
                    '4. Utilisez la liste pour comparer et choisir.',
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
          } else if (snapshot.hasError) {
            return Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade400,
                      ),
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
                        '${snapshot.error}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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

          final formations = snapshot.data!;
          final categories = _getUniqueCategories(formations);

          if (_selectedCategory == null && categories.isNotEmpty) {
            _selectedCategory = categories.first;
          }

          return Column(
            children: [
              // Section Catégories
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategory == category;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? _getCategoryColor(category)
                                    : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? _getCategoryColor(category)
                                      : Colors.grey.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _categoryIcons[category] ?? Icons.category,
                                size: 24,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : _getCategoryColor(category),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.grey.shade800,
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
              ),

              // Nombre de formations
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    FutureBuilder<List<Formation>>(
                      future: _repository.getFormationsByCategory(
                        _selectedCategory!,
                      ),
                      builder: (context, categorySnapshot) {
                        if (categorySnapshot.hasData) {
                          return RichText(
                            text: TextSpan(
                              text: '${categorySnapshot.data?.length ?? 0} ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'formations disponibles',
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.filter_list_rounded,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Liste des formations
              Expanded(
                child:
                    _selectedCategory == null
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.category,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Sélectionnez une catégorie',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                        : FutureBuilder<List<Formation>>(
                          future: _repository.getFormationsByCategory(
                            _selectedCategory!,
                          ),
                          builder: (context, categorySnapshot) {
                            if (categorySnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            } else if (categorySnapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Erreur: ${categorySnapshot.error}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              );
                            } else if (!categorySnapshot.hasData ||
                                categorySnapshot.data!.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucune formation dans cette catégorie',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final categoryFormations = categorySnapshot.data!;

                            // Responsive: use Grid on wide screens, List on narrow
                            return LayoutBuilder(builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final isWide = width >= 800;

                              if (!isWide) {
                                return ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  itemCount: categoryFormations.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final formation = categoryFormations[index];
                                    return _buildFormationListCard(context, formation);
                                  },
                                );
                              }

                              // Grid for wide screens: compute columns based on width
                              final crossAxisCount = (width / 340).floor().clamp(2, 4);
                              return GridView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 3.2,
                                ),
                                itemCount: categoryFormations.length,
                                itemBuilder: (context, index) {
                                  final formation = categoryFormations[index];
                                  return _buildFormationGridCard(context, formation);
                                },
                              );
                            });
                          },
                        ),
              ),
            ],
          );
        },
      ),
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
      default:
        return Colors.grey;
    }
    }

    // Helper: list-style card (existing look)
  Widget _buildFormationListCard(BuildContext context, Formation formation) {
    final categoryColor = _getCategoryColor(formation.category.categorie);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FormationDetailPage(
                formationId: formation.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image arrondie
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: categoryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: formation.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: '${AppConstants.baseUrlImg}/${formation.imageUrl}',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: Icon(
                              _categoryIcons[formation.category.categorie] ?? Icons.school,
                              color: categoryColor,
                              size: 32,
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Icon(
                              _categoryIcons[formation.category.categorie] ?? Icons.school,
                              color: categoryColor,
                              size: 32,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            _categoryIcons[formation.category.categorie] ?? Icons.school,
                            color: categoryColor,
                            size: 32,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Détails
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formation.titre.toUpperCase(),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formation.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text('${formation.duree}h', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${formatPrice(formation.tarif.toInt())} €',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: grid-style card for wide layouts (compact horizontal layout)
  Widget _buildFormationGridCard(BuildContext context, Formation formation) {
    final categoryColor = _getCategoryColor(formation.category.categorie);
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FormationDetailPage(formationId: formation.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: categoryColor.withOpacity(0.25), width: 2),
                ),
                child: ClipOval(
                  child: formation.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: '${AppConstants.baseUrlImg}/${formation.imageUrl}',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: Icon(_categoryIcons[formation.category.categorie] ?? Icons.school, color: categoryColor, size: 36),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Icon(_categoryIcons[formation.category.categorie] ?? Icons.school, color: categoryColor, size: 36),
                          ),
                        )
                      : Center(
                          child: Icon(_categoryIcons[formation.category.categorie] ?? Icons.school, color: categoryColor, size: 36),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      formation.titre,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formation.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                          child: Row(children: [Icon(Icons.schedule, size: 13, color: Colors.grey.shade600), const SizedBox(width: 4), Text('${formation.duree}h', style: TextStyle(fontSize: 11, color: Colors.grey.shade800))]),
                        ),
                        const Spacer(),
                        Text('${formatPrice(formation.tarif.toInt())} €', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

String formatPrice(num price) {
  final formatter = NumberFormat("#,##0", "fr_FR");
  final formatterWithDecimals = NumberFormat("#,##0.00", "fr_FR");

  if (price % 1 == 0) {
    return formatter.format(price);
  } else {
    return formatterWithDecimals.format(price);
  }
}
