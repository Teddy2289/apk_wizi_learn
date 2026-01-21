import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
          return name.contains(query.toLowerCase());
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
                        hintText: 'Rechercher un apprenant...',
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: FormateurTheme.cardShadow,
        border: Border.all(color: FormateurTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: FormateurTheme.accent.withOpacity(0.1),
          backgroundImage: stagiaire['image'] != null ? NetworkImage(stagiaire['image']) : null,
          child: (stagiaire['image'] == null && stagiaire['name'] != null && (stagiaire['name'] as String).isNotEmpty)
              ? Text(
                  (stagiaire['name'] as String)[0].toUpperCase(),
                  style: const TextStyle(color: FormateurTheme.accentDark, fontWeight: FontWeight.bold),
                )
              : (stagiaire['image'] == null ? const Icon(Icons.person, color: FormateurTheme.accentDark) : null),
        ),
        title: Text(
          stagiaire['name'] ?? 'Stagiaire',
          style: const TextStyle(fontWeight: FontWeight.bold, color: FormateurTheme.textPrimary),
        ),
        subtitle: Text(
          stagiaire['email'] ?? '',
          style: const TextStyle(color: FormateurTheme.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: FormateurTheme.textTertiary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StagiaireProfilePage(stagiaireId: stagiaire['id']),
            ),
          );
        },
      ),
    );
  }
}
