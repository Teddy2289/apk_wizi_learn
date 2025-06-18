import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/formation_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/formation_repository.dart';
import 'package:wizi_learn/features/auth/presentation/pages/detail_formation_page.dart';

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
        title: const Text(
          'Nos Formations',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Formation>>(
        future: _futureFormations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur de chargement\n${snapshot.error}',
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Aucune formation disponible',
                style: TextStyle(fontSize: 16),
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
              // Section Catégories - version compacte sans scroll
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  childAspectRatio: 0.8,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getCategoryColor(category)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? _getCategoryColor(category)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _categoryIcons[category] ?? Icons.category,
                              size: 24,
                              color: isSelected ? Colors.white : _getCategoryColor(category),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Nombre de formations
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FutureBuilder<List<Formation>>(
                    future: _repository.getFormationsByCategory(_selectedCategory!),
                    builder: (context, categorySnapshot) {
                      if (categorySnapshot.hasData) {
                        return Text(
                          '${categorySnapshot.data?.length ?? 0} formations',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Liste des formations
              Expanded(
                child: _selectedCategory == null
                    ? const Center(
                  child: Text(
                    'Sélectionnez une catégorie',
                    style: TextStyle(fontSize: 16),
                  ),
                )
                    : FutureBuilder<List<Formation>>(
                  future: _repository.getFormationsByCategory(_selectedCategory!),
                  builder: (context, categorySnapshot) {
                    if (categorySnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (categorySnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erreur: ${categorySnapshot.error}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    } else if (!categorySnapshot.hasData || categorySnapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucune formation dans cette catégorie',
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    final categoryFormations = categorySnapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: categoryFormations.length,
                      itemBuilder: (context, index) {
                        final formation = categoryFormations[index];
                        final categoryColor = _getCategoryColor(formation.category.categorie);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius.circular(
                                20),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.1),
                                border: Border.all(color: categoryColor.withOpacity(0.3)),
                                borderRadius:
                                BorderRadius.circular(
                                    12),
                              ),
                              child: formation.imageUrl != null
                                  ? Image.network(
                                '${AppConstants.baseUrlImg}/${formation.imageUrl}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  _categoryIcons[formation.category.categorie] ?? Icons.school,
                                  color: categoryColor,
                                ),
                              )
                                  : Icon(
                                _categoryIcons[formation.category.categorie] ?? Icons.school,
                                color: categoryColor,
                                size: 30,
                              ),
                            ),
                            title: Text(
                              formation.titre,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  formation.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${formation.duree}h',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${formatPrice(formation.tarif)} €',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
                          ),
                        );
                      },
                    );
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