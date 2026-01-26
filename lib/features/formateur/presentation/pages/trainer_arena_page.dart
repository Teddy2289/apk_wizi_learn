import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';
import 'package:wizi_learn/features/formateur/presentation/widgets/formateur_drawer_menu.dart';

class TrainerArenaPage extends StatefulWidget {
  const TrainerArenaPage({super.key});

  @override
  State<TrainerArenaPage> createState() => _TrainerArenaPageState();
}

class _TrainerArenaPageState extends State<TrainerArenaPage> {
  late final ApiClient _apiClient;
  bool _loading = true;
  List<dynamic> _ranking = [];
  List<dynamic> _formations = [];
  String _selectedFormationId = 'all';
  String _selectedFormateurId = 'all';
  String _searchQuery = '';
  bool _showSearch = false;
  String _period = 'all';
  int? _expandedFormateurId;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      await Future.wait([
        _fetchFormations(),
        _fetchRanking(),
      ]);
    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchFormations() async {
    try {
      final response = await _apiClient.get('/formateur/formations');
      if (mounted) {
        setState(() {
          _formations = response.data['formations'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching formations: $e');
    }
  }

  Future<void> _fetchRanking() async {
    try {
      final queryParams = {
        'period': _period,
        if (_selectedFormationId != 'all') 'formation_id': _selectedFormationId,
      };
      
      final response = await _apiClient.get(
        '/formateur/classement/arena',
        queryParameters: queryParams,
      );
      
      if (mounted) {
        setState(() {
          _ranking = response.data ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching ranking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRanking = _ranking.where((f) {
      final name = '${f['prenom']} ${f['nom']}'.toLowerCase();
      final matchesName = name.contains(_searchQuery.toLowerCase());
      final matchesFormateur = _selectedFormateurId == 'all' || 
          f['id'].toString() == _selectedFormateurId;
      return matchesName && matchesFormateur;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: FormateurTheme.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: FormateurTheme.accent), // Fixed color
            const SizedBox(width: 8),
            const Text(
              'Arène des Formateurs',
              style: TextStyle(
                color: FormateurTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          if (_showSearch)
            Container(
              width: 200,
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Rechercher...',
                  contentPadding: EdgeInsets.only(bottom: 12),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: _showSearch ? FormateurTheme.accent : Colors.grey[600], // Fixed color
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) _searchQuery = '';
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: FormateurDrawerMenu(onLogout: () {}), // Fixed args
      body: _loading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await Future.wait([_fetchFormations(), _fetchRanking()]);
              }, // Fixed refresh logic to reload both
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Period Switcher
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _buildPeriodButton('week', 'Hebdomadaire'),
                          _buildPeriodButton('month', 'Mensuel'),
                          _buildPeriodButton('all', 'Tout temps'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filters
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            value: _selectedFormationId,
                            items: [
                              const DropdownMenuItem(value: 'all', child: Text('Toutes les Formations')),
                              ..._formations.map((f) => DropdownMenuItem(
                                value: f['id'].toString(),
                                child: Text(f['titre'] ?? f['nom'] ?? 'Sans titre', overflow: TextOverflow.ellipsis),
                              )),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedFormationId = val;
                                  _selectedFormateurId = 'all';
                                });
                                _fetchRanking();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            value: _selectedFormateurId,
                            items: [
                              const DropdownMenuItem(value: 'all', child: Text('Tous les Formateurs')),
                              ..._ranking.map((f) => DropdownMenuItem(
                                value: f['id'].toString(),
                                child: Text('${f['prenom']} ${f['nom']}', overflow: TextOverflow.ellipsis),
                              )),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedFormateurId = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Leaderboard
                    if (filteredRanking.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredRanking.length,
                        itemBuilder: (context, index) {
                          final formateur = filteredRanking[index];
                          final isExpanded = _expandedFormateurId == formateur['id'];
                          
                          return _buildFormateurCard(formateur, index, isExpanded);
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodButton(String id, String label) {
    final isSelected = _period == id;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _period = id);
          _fetchRanking();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
            ] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildFormateurCard(dynamic formateur, int index, bool isExpanded) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              _expandedFormateurId = isExpanded ? null : formateur['id'];
            }),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          image: formateur['image'] != null
                              ? DecorationImage(
                                  image: NetworkImage(
                                    AppConstants.getUserImageUrl(formateur['image']),
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: formateur['image'] == null
                            ? Center(
                                child: Text(
                                  '${formateur['prenom']?[0] ?? ''}${formateur['nom']?[0] ?? ''}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        top: -6,
                        left: -6,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == 0 ? FormateurTheme.accent // Fixed color
                                : index == 1 ? Colors.grey[400] 
                                : index == 2 ? Colors.brown[400] 
                                : Colors.grey[100],
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: index <= 2 ? Colors.black : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${formateur['prenom']} ${formateur['nom']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: FormateurTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Équipe de ${formateur['total_stagiaires']} Apprentis',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${formateur['total_points']} Pts Total',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: FormateurTheme.accent, // Fixed color
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(top: BorderSide(color: Colors.grey[100]!)),
              ),
              padding: const EdgeInsets.all(16),
              child: _buildStagiairesGrid(formateur['stagiaires'] ?? []),
            ),
        ],
      ),
    );
  }

  Widget _buildStagiairesGrid(List<dynamic> stagiaires) {
    if (stagiaires.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'AUCUN DÉFI RELEVÉ PAR CETTE ÉQUIPE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 400 ? 2 : 1;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(stagiaires.length, (index) {
            final stagiaire = stagiaires[index];
            return Container(
              width: (constraints.maxWidth - 12) / crossAxisCount - (crossAxisCount == 1 ? 0 : 0.1),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      image: stagiaire['image'] != null
                          ? DecorationImage(
                              image: NetworkImage(
                                AppConstants.getUserImageUrl(stagiaire['image']),
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: stagiaire['image'] == null
                        ? Center(
                            child: Text(
                              '${stagiaire['prenom']?[0] ?? ''}${stagiaire['nom']?[0] ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey[400],
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${stagiaire['prenom']} ${stagiaire['nom']}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${stagiaire['points']} PTS', // Corrected from points
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: FormateurTheme.accent, // Fixed color
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "L'ARÈNE EST VIDE",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.grey[400],
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Revenez plus tard quand les formateurs auront formé leurs équipes.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
