import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  late final Dio _dio;
  late Future<List<Map<String, dynamic>>> _futureTutorials;
  String? _selectedCategory;

  final Map<String, IconData> _categoryIcons = {
    'Word': Icons.description,
    'Excel': Icons.table_chart,
    'PowerPoint': Icons.slideshow,
    'Outlook': Icons.mail,
  };

  @override
  void initState() {
    super.initState();
    _dio = Dio();
    _futureTutorials = _fetchTutorials();
  }

  Future<List<Map<String, dynamic>>> _fetchTutorials() async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/medias/tutoriels');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tutoriels',
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureTutorials,
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
                'Aucun tutoriel disponible',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final tutorials = snapshot.data!;
          final categories = _getUniqueCategories(tutorials);

          if (_selectedCategory == null && categories.isNotEmpty) {
            _selectedCategory = categories.first;
          }

          return Column(
            children: [
              // Section Catégories
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

              // Liste des tutoriels
              Expanded(
                child: _selectedCategory == null
                    ? const Center(
                        child: Text(
                          'Sélectionnez une catégorie',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: tutorials
                            .where((t) => t['category'] == _selectedCategory)
                            .length,
                        itemBuilder: (context, index) {
                          final tutorial = tutorials
                              .where((t) => t['category'] == _selectedCategory)
                              .toList()[index];
                          final categoryColor = _getCategoryColor(tutorial['category']);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
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
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _categoryIcons[tutorial['category']] ?? Icons.school,
                                  color: categoryColor,
                                  size: 30,
                                ),
                              ),
                              title: Text(
                                tutorial['title'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    tutorial['description'],
                                    style: const TextStyle(fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.play_circle_filled,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${tutorial['duration']} min',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () {
                                // TODO: Implémenter la navigation vers la page de détail du tutoriel
                              },
                            ),
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

  List<String> _getUniqueCategories(List<Map<String, dynamic>> tutorials) {
    return tutorials.map((t) => t['category'] as String).toSet().toList();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Word':
        return const Color(0xFF3D9BE9);
      case 'Excel':
        return const Color(0xFFA55E6E);
      case 'PowerPoint':
        return const Color(0xFFFFC533);
      case 'Outlook':
        return const Color(0xFF9392BE);
      default:
        return Colors.grey;
    }
  }
}
