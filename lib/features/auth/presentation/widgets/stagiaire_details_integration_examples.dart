// EXEMPLE D'INTÉGRATION DU DIALOG DANS LES WIDGETS DE CLASSEMENT
// Ce fichier montre comment intégrer le StagiaireDetailsDialog dans vos widgets existants

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/stagiaire_details_dialog.dart';

// ===================================================================
// EXEMPLE 1: Intégration dans GlobalRankingWidget
// ===================================================================

class GlobalRankingWidgetExample extends StatelessWidget {
  final List<Map<String, dynamic>> rankings;
  
  const GlobalRankingWidgetExample({super.key, required this.rankings});

  // Méthode pour récupérer les détails du stagiaire
  Future<Map<String, dynamic>> _fetchStagiaireDetails(int stagiaireId) async {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final baseUrl = 'YOUR_API_URL'; // Remplacer par votre URL
    
    try {
      final dio = Dio();
      final response = await dio.get(
        '$baseUrl/stagiaires/$stagiaireId/details',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur lors du chargement des détails: $e');
    }
  }

  // Méthode pour afficher le dialog
  void _showStagiaireDetails(BuildContext context, int stagiaireId) async {
    // Afficher un loader pendant le chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final details = await _fetchStagiaireDetails(stagiaireId);
      
      // Fermer le loader
      if (context.mounted) Navigator.pop(context);
      
      // Afficher le dialog avec les détails
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => StagiaireDetailsDialog(
            stagiaireData: details,
          ),
        );
      }
    } catch (e) {
      // Fermer le loader
      if (context.mounted) Navigator.pop(context);
      
      // Afficher l'erreur
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: rankings.length,
      itemBuilder: (context, index) {
        final stagiaire = rankings[index];
        
        return GestureDetector(
          // ⭐ IMPORTANT: Ajouter onTap pour ouvrir le dialog
          onTap: () => _showStagiaireDetails(
            context, 
            stagiaire['id'] as int,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Badge rang
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      stagiaire['rang'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info stagiaire
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stagiaire['firstname'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${stagiaire['score']} points',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Icône info pour indiquer que c'est cliquable
                Icon(Icons.info_outline, color: Colors.grey[400]),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ===================================================================
// EXEMPLE 2: Intégration avec Filtrage Quiz
// ===================================================================

class QuizSelectionWithFilterExample extends StatefulWidget {
  const QuizSelectionWithFilterExample({super.key});

  @override
  State<QuizSelectionWithFilterExample> createState() => _QuizSelectionWithFilterExampleState();
}

class _QuizSelectionWithFilterExampleState extends State<QuizSelectionWithFilterExample> {
  int _userPoints = 0;
  List<Map<String, dynamic>> _allQuizzes = [];
  List<Map<String, dynamic>> _filteredQuizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Récupérer les points utilisateur
      _userPoints = await _fetchUserPoints();
      
      // Récupérer tous les quiz
      _allQuizzes = await _fetchAllQuizzes();
      
      // Filtrer selon les points
      _filteredQuizzes = filterQuizByPoints(_allQuizzes, _userPoints);
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<int> _fetchUserPoints() async {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    final baseUrl = 'YOUR_API_URL';
    
    final dio = Dio();
    final response = await dio.get(
      '$baseUrl/users/me/points',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    
    return response.data['totalPoints'] as int;
  }

  Future<List<Map<String, dynamic>>> _fetchAllQuizzes() async {
    // Logique pour récupérer tous les quiz
    // À adapter selon votre API
    return [];
  }

  String _getNextLevel() {
    if (_userPoints < 50) return 'Intermédiaire';
    if (_userPoints < 100) return 'Expert';
    return '';
  }

  int _getPointsNeeded() {
    if (_userPoints < 50) return 50 - _userPoints;
    if (_userPoints < 100) return 100 - _userPoints;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Badge niveau actuel
        Padding(
          padding: const EdgeInsets.all(16),
          child: QuizLevelBadge(totalPoints: _userPoints),
        ),
        
        // Liste des quiz accessibles
        Expanded(
          child: ListView.builder(
            itemCount: _filteredQuizzes.length,
            itemBuilder: (context, index) {
              final quiz = _filteredQuizzes[index];
              return ListTile(
                title: Text(quiz['titre'] ?? ''),
                subtitle: Text('Niveau: ${quiz['niveau']}'),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                ),
                onTap: () {
                  // Naviguer vers le quiz
                },
              );
            },
          ),
        ),
        
        // Notice niveau bloqué si applicable
        if (_userPoints < 100)
          Padding(
            padding: const EdgeInsets.all(16),
            child: LockedLevelNotice(
              nextLevel: _getNextLevel(),
              pointsNeeded: _getPointsNeeded(),
            ),
          ),
      ],
    );
  }
}

// ===================================================================
// EXEMPLE 3: Widget Card Stagiaire Cliquable Réutilisable
// ===================================================================

class StagiaireCard extends StatelessWidget {
  final Map<String, dynamic> stagiaire;
  final VoidCallback? onTap;
  
  const StagiaireCard({
    super.key,
    required this.stagiaire,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundImage: stagiaire['avatar'] != null
                    ? NetworkImage(stagiaire['avatar'])
                    : null,
                child: stagiaire['avatar'] == null
                    ? Text(
                        stagiaire['firstname']?[0]?.toUpperCase() ?? '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stagiaire['firstname'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${stagiaire['score']} points',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Badge rang
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '#${stagiaire['rang']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================================================================
// EXEMPLE D'UTILISATION
// ===================================================================

class ExampleUsage extends StatelessWidget {
  const ExampleUsage({super.key});

  @override
  Widget build(BuildContext context) {
    final stagiaires = [
      {'id': 1, 'firstname': 'John', 'rang': 1, 'score': 850, 'avatar': null},
      {'id': 2, 'firstname': 'Jane', 'rang': 2, 'score': 820, 'avatar': null},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Classement')),
      body: ListView.builder(
        itemCount: stagiaires.length,
        itemBuilder: (context, index) {
          final stagiaire = stagiaires[index];
          
          return StagiaireCard(
            stagiaire: stagiaire,
            onTap: () async {
              // Utiliser la même logique de _fetchStagiaireDetails
              // et showDialog que dans l'exemple 1
            },
          );
        },
      ),
    );
  }
}
