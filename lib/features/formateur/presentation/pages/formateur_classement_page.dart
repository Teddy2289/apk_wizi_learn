import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/presentation/pages/stagiaire_profile_page.dart';

class FormateurClassementPage extends StatefulWidget {
  const FormateurClassementPage({super.key});

  @override
  State<FormateurClassementPage> createState() => _FormateurClassementPageState();
}

class _FormateurClassementPageState extends State<FormateurClassementPage> {
  final ApiClient _apiClient = ApiClient(
    dio: Dio(),
    storage: const FlutterSecureStorage(),
  );

  List<dynamic> _ranking = [];
  bool _loading = true;
  String _selectedPeriod = 'all';

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

  Future<void> _loadRanking() async {
    setState(() => _loading = true);
    try {
      final response = await _apiClient.get(
        '/formateur/classement/mes-stagiaires',
        queryParameters: {'period': _selectedPeriod},
      );
      setState(() {
        _ranking = response.data['ranking'] ?? [];
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement classement: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classement Stagiaires'),
        backgroundColor: const Color(0xFFF7931E),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPeriodChip('all', 'Tout'),
                _buildPeriodChip('month', 'Mois'),
                _buildPeriodChip('week', 'Semaine'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadRanking,
                    child: _ranking.isEmpty
                        ? const Center(child: Text('Aucun classement disponible'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: _ranking.length,
                            itemBuilder: (context, index) {
                              final stagiaire = _ranking[index];
                              final rank = stagiaire['rank'];
                              
                              return Card(
                                color: _getRankColor(rank),
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StagiaireProfilePage(
                                          stagiaireId: stagiaire['id'] as int,
                                        ),
                                      ),
                                    );
                                  },
                                  leading: _buildRankIcon(rank),
                                  title: Text(
                                    '${stagiaire['prenom']} ${stagiaire['nom']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(stagiaire['email']),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Chip(
                                            label: Text('${stagiaire['total_points']} pts'),
                                            backgroundColor: Colors.blue.shade100,
                                          ),
                                          const SizedBox(width: 8),
                                          Text('${stagiaire['total_quiz']} quiz'),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: stagiaire['avg_score'] >= 70
                                          ? Colors.green
                                          : Colors.grey,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${stagiaire['avg_score']}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPeriod = value);
          _loadRanking();
        }
      },
      selectedColor: const Color(0xFFF7931E).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFF7931E) : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildRankIcon(int rank) {
    IconData icon;
    Color color;

    switch (rank) {
      case 1:
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      case 2:
        icon = Icons.emoji_events;
        color = Colors.grey;
        break;
      case 3:
        icon = Icons.emoji_events;
        color = Colors.brown;
        break;
      default:
        icon = Icons.military_tech;
        color = Colors.grey.shade400;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(icon, size: 40, color: color),
        Positioned(
          bottom: 4,
          child: Text(
            '#$rank',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade50;
      case 2:
        return Colors.grey.shade50;
      case 3:
        return Colors.orange.shade50;
      default:
        return Colors.white;
    }
  }
}
