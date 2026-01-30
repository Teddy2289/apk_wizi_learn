import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/arena_model.dart';
import 'package:wizi_learn/features/formateur/data/repositories/arena_repository.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';
import 'package:wizi_learn/features/formateur/data/repositories/formation_management_repository.dart';
import 'package:wizi_learn/features/formateur/data/models/formation_management_model.dart';
// import 'package:wizi_learn/features/formateur/data/repositories/formateur_repository.dart'; // Not needed if focusing on ArenaRepository

class ArenaPage extends StatefulWidget {
  const ArenaPage({super.key});

  @override
  State<ArenaPage> createState() => _ArenaPageState();
}

class _ArenaPageState extends State<ArenaPage> {
  late final ArenaRepository _repository;
  late final FormationManagementRepository _formationRepository;
  
  List<ArenaFormateur> _ranking = [];
  List<FormationWithStats> _formations = [];
  bool _loading = true;
  String? _error;

  // Filters
  String _searchQuery = '';
  String _selectedPeriod = 'all'; // week, month, all
  String _selectedFormationId = 'all';
  String _selectedFormateurId = 'all';
  bool _showSearch = false;
  int? _expandedFormateurId;

  // Controllers
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(dio: Dio(), storage: const FlutterSecureStorage());
    _repository = ArenaRepository(apiClient: apiClient);
    _formationRepository = FormationManagementRepository(apiClient: apiClient);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Parallel fetch
      final results = await Future.wait([
        _repository.getArenaRanking(
          period: _selectedPeriod,
          formationId: _selectedFormationId == 'all' ? null : _selectedFormationId,
        ),
        if (_formations.isEmpty) _formationRepository.getAvailableFormations(),
      ]);

      setState(() {
        _ranking = results[0] as List<ArenaFormateur>;
        if (_formations.isEmpty) {
          _formations = results[1] as List<FormationWithStats>;
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur de chargement: $e';
          _loading = false;
        });
      }
    }
  }

  void _onPeriodChanged(String period) {
    if (_selectedPeriod == period) return;
    setState(() => _selectedPeriod = period);
    _loadData();
  }

  void _onFormationChanged(String? formationId) {
    if (_selectedFormationId == formationId) return;
    setState(() {
      _selectedFormationId = formationId ?? 'all';
      _selectedFormateurId = 'all'; // Reset Formateur filter
    });
    _loadData();
  }

  List<ArenaFormateur> get _filteredRanking {
    return _ranking.where((f) {
      final nameMatch = '${f.prenom} ${f.nom}'.toLowerCase().contains(_searchQuery.toLowerCase());
      final formateurMatch = _selectedFormateurId == 'all' || f.id.toString() == _selectedFormateurId;
      return nameMatch && formateurMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormateurTheme.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(LucideIcons.gamepad2, color: FormateurTheme.accent, size: 24),
            SizedBox(width: 12),
            Text('Arène des Formateurs'),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: FormateurTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          fontFamily: 'Montserrat',
          letterSpacing: -0.5,
        ),
        actions: [
          AnimatedContainer(
            duration: 200.ms,
            width: _showSearch ? 200 : 0,
            margin: const EdgeInsets.only(right: 8),
            child: _showSearch
                ? TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      hintStyle: const TextStyle(fontSize: 13),
                    ),
                    style: const TextStyle(fontSize: 13),
                  )
                : null,
          ),
          IconButton(
            icon: Icon(_showSearch ? Icons.close : LucideIcons.search, color: _showSearch ? FormateurTheme.accentDark : FormateurTheme.textSecondary),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
            style: IconButton.styleFrom(
              backgroundColor: _showSearch ? FormateurTheme.accent : Colors.transparent,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: FormateurTheme.accent,
        child: Column(
          children: [
            // Period Filter
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FormateurTheme.border),
                ),
                child: Row(
                  children: [
                    _buildPeriodTab('Hebdomadaire', 'week'),
                    _buildPeriodTab('Mensuel', 'month'),
                    _buildPeriodTab('Tout temps', 'all'),
                  ],
                ),
              ),
            ),

            // Dropdown Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDropdown<String>(
                      value: _selectedFormationId,
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('Toutes formations')),
                        ..._formations.map((f) => DropdownMenuItem(value: f.id.toString(), child: Text(f.titre))),
                      ],
                      onChanged: _onFormationChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown<String>(
                      value: _selectedFormateurId,
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('Tous formateurs')),
                        ..._ranking.map((f) => DropdownMenuItem(value: f.id.toString(), child: Text('${f.prenom} ${f.nom}'))),
                      ],
                      onChanged: (val) => setState(() => _selectedFormateurId = val ?? 'all'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _loading 
                ? const Center(child: CircularProgressIndicator(color: FormateurTheme.accent))
                : _filteredRanking.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.trophy, size: 64, color: FormateurTheme.border),
                          const SizedBox(height: 16),
                          const Text('L\'ARÈNE EST VIDE', style: TextStyle(color: FormateurTheme.textTertiary, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          const SizedBox(height: 8),
                          if (_searchQuery.isNotEmpty)
                             Text('Aucun résultat pour "$_searchQuery"', style: const TextStyle(color: FormateurTheme.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                      itemCount: _filteredRanking.length,
                      itemBuilder: (context, index) {
                        final formateur = _filteredRanking[index];
                        return _buildTeacherCard(formateur, index)
                            .animate(delay: (index * 50).ms)
                            .fadeIn(duration: 400.ms, curve: Curves.easeOutQuad)
                            .slideY(begin: 10, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String label, String id) {
    final isSelected = _selectedPeriod == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onPeriodChanged(id),
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? FormateurTheme.textPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: isSelected ? Colors.white : FormateurTheme.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({required T value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FormateurTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: FormateurTheme.textSecondary),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FormateurTheme.textPrimary, fontFamily: 'Montserrat'),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildTeacherCard(ArenaFormateur f, int index) {
    final isExpanded = _expandedFormateurId == f.id;
    final isTop3 = index < 3;
    final rankColor = index == 0 ? const Color(0xFFEAB308) : index == 1 ? const Color(0xFF94A3B8) : index == 2 ? const Color(0xFFB45309) : FormateurTheme.background;
    final rankTextColor = index < 3 ? Colors.white : FormateurTheme.textTertiary;

    return AnimatedContainer(
      duration: 300.ms,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isExpanded ? FormateurTheme.accent : FormateurTheme.border,
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: [
          if (isExpanded)
            BoxShadow(color: FormateurTheme.accent.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expandedFormateurId = isExpanded ? null : f.id),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Rank & Avatar
                  Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: rankColor.withOpacity(0.2), width: 1),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: FormateurTheme.background,
                          backgroundImage: f.image != null && f.image!.isNotEmpty
                              ? NetworkImage(AppConstants.getUserImageUrl(f.image!))
                              : null,
                          child: f.image == null
                              ? Text(
                                  f.prenom.isNotEmpty ? f.prenom[0].toUpperCase() : '?',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: FormateurTheme.textSecondary),
                                )
                              : null,
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: rankColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(color: rankTextColor, fontWeight: FontWeight.w900, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${f.prenom} ${f.nom}'.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: FormateurTheme.textPrimary, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.users, size: 14, color: FormateurTheme.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              'Équipe de ${f.totalStagiaires} Apprenti${f.totalStagiaires > 1 ? 's' : ''}',
                              style: const TextStyle(color: FormateurTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Points & Expand Icon
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${f.totalPoints} PTS',
                        style: const TextStyle(color: FormateurTheme.accentDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                       Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: FormateurTheme.textTertiary,
                        size: 20
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content (Stagiaires List)
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0, width: double.infinity),
            secondChild: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: FormateurTheme.background,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(22), bottomRight: Radius.circular(22)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: f.stagiaires.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'AUCUN DÉFI RELEVÉ PAR CETTE ÉQUIPE',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: FormateurTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, fontStyle: FontStyle.italic),
                        ),
                      )
                    : Column(
                        children: f.stagiaires.asMap().entries.map((entry) {
                          final s = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: FormateurTheme.border.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: FormateurTheme.background,
                                  backgroundImage: s.image != null && s.image!.isNotEmpty
                                      ? NetworkImage(AppConstants.getUserImageUrl(s.image!))
                                      : null,
                                  child: s.image == null
                                      ? Text(s.prenom.isNotEmpty ? s.prenom[0] : '?', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FormateurTheme.textSecondary))
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${s.prenom} ${s.nom}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: FormateurTheme.textPrimary)),
                                      Text('${s.points} PTS', style: const TextStyle(color: FormateurTheme.accentDark, fontSize: 10, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: FormateurTheme.accent, shape: BoxShape.circle),
                                ),
                              ],
                            ),
                          ).animate(delay: (entry.key * 30).ms).fadeIn().slideX(begin: -0.1);
                        }).toList(),
                      ),
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: 250.ms,
          ),
        ],
      ),
    );
  }
}
