import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/repositories/analytics_repository.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';
import 'package:wizi_learn/features/formateur/presentation/pages/stagiaire_profile_page.dart';
import 'package:wizi_learn/features/formateur/presentation/widgets/formateur_drawer_menu.dart';
import 'package:wizi_learn/features/formateur/presentation/widgets/dashboard_shimmer.dart';

class FormateurStagiairesPage extends StatefulWidget {
  const FormateurStagiairesPage({super.key});

  @override
  State<FormateurStagiairesPage> createState() => _FormateurStagiairesPageState();
}

class _FormateurStagiairesPageState extends State<FormateurStagiairesPage> {
  late final AnalyticsRepository _repository;
  bool _loading = true;
  List<dynamic> _stagiaires = [];
  List<dynamic> _filteredStagiaires = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _repository = AnalyticsRepository(
      apiClient: ApiClient(dio: Dio(), storage: const FlutterSecureStorage()),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Using student comparison endpoint as it returns the list of students with stats
      final data = await _repository.getStudentsComparison();
      final List<dynamic> students = data['performance'] as List<dynamic>? ?? [];
      setState(() {
        _stagiaires = students;
        _filteredStagiaires = students;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement stagiaires: $e');
      setState(() => _loading = false);
    }
  }

  void _filterStagiaires(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStagiaires = _stagiaires;
      } else {
        _filteredStagiaires = _stagiaires.where((s) {
          final name = (s['name'] ?? '').toString().toLowerCase();
          final prenom = (s['prenom'] ?? '').toString().toLowerCase();
          final nom = (s['nom'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || 
                 prenom.contains(searchLower) || 
                 nom.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormateurTheme.background,
      appBar: AppBar(
        title: const Text('Mes Stagiaires'),
        backgroundColor: Colors.white,
        foregroundColor: FormateurTheme.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: FormateurTheme.textPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 20,
          fontFamily: 'Montserrat',
        ),
      ),
      drawer: FormateurDrawerMenu(
         onLogout: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FormateurTheme.accent))
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: FormateurTheme.cardShadow,
                      border: Border.all(color: FormateurTheme.border),
                    ),
                    child: TextField(
                      onChanged: _filterStagiaires,
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un stagiaire...',
                        hintStyle: TextStyle(color: FormateurTheme.textTertiary, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: FormateurTheme.textTertiary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ),
                
                // List
                Expanded(
                  child: _filteredStagiaires.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty ? 'Aucun stagiaire trouvé' : 'Aucun résultat',
                            style: const TextStyle(color: FormateurTheme.textSecondary, fontWeight: FontWeight.bold),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          itemCount: _filteredStagiaires.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final s = _filteredStagiaires[index];
                            return _buildStagiaireCard(s);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStagiaireCard(dynamic stagiaire) {
    final String prenom = (stagiaire['prenom'] ?? '').toString();
    final String nom = (stagiaire['nom'] ?? '').toString();
    final String name = (stagiaire['name'] ?? '').toString();
    
    String displayName = '$prenom $nom'.trim();
    if (displayName.isEmpty) {
      displayName = name.isNotEmpty ? name : 'Stagiaire';
    }
    
    final String finalName = displayName;
    final int averageScore = int.tryParse(stagiaire['average_score']?.toString() ?? '0') ?? 0;
    final int points = int.tryParse(stagiaire['total_points']?.toString() ?? '0') ?? 0;
    final int streak = int.tryParse(stagiaire['total_logins']?.toString() ?? '0') ?? 0;

    return Container(
      decoration: FormateurTheme.premiumCardDecoration,
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StagiaireProfilePage(stagiaireId: stagiaire['id']),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: FormateurTheme.accent.withOpacity(0.2), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: FormateurTheme.background,
                      backgroundImage: stagiaire['image'] != null && stagiaire['image'].toString().isNotEmpty 
                          ? NetworkImage(AppConstants.getUserImageUrl(stagiaire['image'].toString())) : 
                          (stagiaire['avatar'] != null && stagiaire['avatar'].toString().isNotEmpty 
                              ? NetworkImage(AppConstants.getUserImageUrl(stagiaire['avatar'].toString())) : null),
                      child: ((stagiaire['image'] == null || stagiaire['image'].toString().isEmpty) && 
                              (stagiaire['avatar'] == null || stagiaire['avatar'].toString().isEmpty) && 
                              finalName != 'Stagiaire')
                          ? Text(
                              finalName[0].toUpperCase(),
                              style: const TextStyle(color: FormateurTheme.accentDark, fontWeight: FontWeight.w900, fontSize: 18),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          finalName.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: FormateurTheme.textPrimary, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stagiaire['email'] ?? '',
                          style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: FormateurTheme.border, size: 16),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: FormateurTheme.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FormateurTheme.border.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniMetric('SCORE', '$averageScore%', FormateurTheme.success),
                    _buildMiniMetric('POINTS', '$points', FormateurTheme.accentDark),
                    _buildMiniMetric('SÉRIE', '${streak}j', Colors.orange),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color, letterSpacing: -1),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 0.5),
        ),
      ],
    );
  }
}
