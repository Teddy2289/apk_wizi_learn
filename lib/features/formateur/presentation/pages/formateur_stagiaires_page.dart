import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/repositories/analytics_repository.dart';
import 'package:intl/intl.dart';
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
        leading: Navigator.canPop(context) 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            )
          : null,
        titleTextStyle: const TextStyle(
          color: FormateurTheme.textPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          fontFamily: 'Montserrat',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: FormateurTheme.border, height: 1),
        ),
      ),
      drawer: FormateurDrawerMenu(
         onLogout: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FormateurTheme.accent))
          : Column(
              children: [
                _buildPremiumHeader(),
                
                // List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: FormateurTheme.accent,
                    child: _filteredStagiaires.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.all(24),
                            itemCount: _filteredStagiaires.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final s = _filteredStagiaires[index];
                              return _buildStagiaireCard(s);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: FormateurTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_alt_rounded, size: 12, color: FormateurTheme.accentDark),
                SizedBox(width: 8),
                Text(
                  'Gestion Stagiaires',
                  style: TextStyle(
                    color: FormateurTheme.accentDark,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Mes Stagiaires',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: FormateurTheme.textPrimary,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Gérez et suivez la progression de vos apprenants en temps réel.",
            style: TextStyle(
              color: FormateurTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: FormateurTheme.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FormateurTheme.border),
      ),
      child: TextField(
        onChanged: _filterStagiaires,
        decoration: const InputDecoration(
          hintText: 'Rechercher un apprenant...',
          hintStyle: TextStyle(color: FormateurTheme.textTertiary, fontSize: 13, fontWeight: FontWeight.w700),
          prefixIcon: Icon(Icons.search_rounded, color: FormateurTheme.accent, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
    
    final int averageScore = int.tryParse(stagiaire['average_score']?.toString() ?? '0') ?? 0;
    final int points = int.tryParse(stagiaire['total_points']?.toString() ?? '0') ?? 0;
    final int streak = int.tryParse(stagiaire['total_logins']?.toString() ?? '0') ?? 0;
    final String lastActive = (stagiaire['last_active'] ?? '').toString();
    final String telephone = (stagiaire['telephone'] ?? '').toString();

    DateTime? lastActiveDate;
    if (lastActive.isNotEmpty) {
      try {
        lastActiveDate = DateTime.parse(lastActive);
      } catch (_) {}
    }

    return Container(
      decoration: FormateurTheme.premiumCardDecoration,
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: FormateurTheme.accent.withOpacity(0.1),
                    backgroundImage: stagiaire['avatar'] != null && stagiaire['avatar'].toString().isNotEmpty 
                        ? NetworkImage(AppConstants.getUserImageUrl(stagiaire['avatar'].toString())) : null,
                    child: (stagiaire['avatar'] == null || stagiaire['avatar'].toString().isEmpty)
                        ? Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                            style: const TextStyle(color: FormateurTheme.accentDark, fontWeight: FontWeight.w900, fontSize: 18),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: FormateurTheme.textPrimary, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.mail_outline_rounded, size: 14, color: FormateurTheme.textTertiary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                stagiaire['email'] ?? '',
                                style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (telephone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 14, color: FormateurTheme.textTertiary),
                              const SizedBox(width: 6),
                              Text(
                                telephone,
                                style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: FormateurTheme.border, size: 24),
                ],
              ),
              const SizedBox(height: 20),
              if (lastActiveDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 14, color: FormateurTheme.accent),
                      const SizedBox(width: 8),
                      Text(
                        'Dernière activité : ',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: FormateurTheme.accent.withOpacity(0.7), letterSpacing: 0.5),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(lastActiveDate),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: FormateurTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FormateurTheme.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FormateurTheme.border.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniMetric('Score', '$averageScore%', FormateurTheme.success),
                    // _buildMiniMetric('POINTS', '$points', FormateurTheme.accentDark),
                    _buildMiniMetric('Série', '${streak}j', Colors.orange),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.people_outline_rounded, size: 48, color: FormateurTheme.border),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun stagiaire trouvé',
            style: TextStyle(color: FormateurTheme.textTertiary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }
}
