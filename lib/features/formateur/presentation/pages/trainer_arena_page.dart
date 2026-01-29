import 'dart:convert';
import 'package:flutter/services.dart';
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
  Map<String, dynamic>? _currentUser;

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
        _loadCurrentUser(),
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

  Future<void> _loadCurrentUser() async {
    try {
      final userStr = await const FlutterSecureStorage().read(key: 'auth_user');
      if (userStr != null) {
        setState(() {
          _currentUser = jsonDecode(userStr);
        });
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the current user's ID for comparison
    final int? currentUserId = _currentUser?['id'];

    final filteredRanking = _ranking.where((f) {
      final name = '${f['prenom']} ${f['nom']}'.toLowerCase();
      final matchesName = name.contains(_searchQuery.toLowerCase());
      final matchesFormateur = _selectedFormateurId == 'all' || 
          f['id'].toString() == _selectedFormateurId;
      return matchesName && matchesFormateur;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        centerTitle: false,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ColorFilter.mode(Colors.white.withOpacity(0.8), BlendMode.srcOver),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.gamepad_outlined, color: Color(0xFFFACC15), size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'Arène Formateurs',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _showSearch ? 180 : 0,
            height: 36,
            child: _showSearch 
              ? TextField(
                  autofocus: true,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                )
              : null,
          ),
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
              color: _showSearch ? const Color(0xFFFACC15) : const Color(0xFF64748B),
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
      drawer: FormateurDrawerMenu(onLogout: () {}),
      body: _loading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)))
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchData();
              },
              color: const Color(0xFFFACC15),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                children: [
                  // Period Switcher (Premium Look)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        _buildPeriodButton('week', 'Hebdomadaire'),
                        _buildPeriodButton('month', 'Mensuel'),
                        _buildPeriodButton('all', 'Tout temps'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Filters
                  Row(
                    children: [
                      Expanded(
                        child: _buildPremiumDropdown(
                          value: _selectedFormationId,
                          hint: 'Toutes les Formations',
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
                        child: _buildPremiumDropdown(
                          value: _selectedFormateurId,
                          hint: 'Tous les Formateurs',
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
                  const SizedBox(height: 28),

                  // Leaderboard
                  if (filteredRanking.isEmpty)
                    _buildEmptyState()
                  else
                    ...filteredRanking.asMap().entries.map((entry) {
                      final index = entry.key;
                      final formateur = entry.value;
                      final isExpanded = _expandedFormateurId == formateur['id'];
                      final bool isMe = currentUserId != null && currentUserId == formateur['id'];
                      
                      return _buildPremiumFormateurCard(formateur, index, isExpanded, isMe);
                    }).toList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildPremiumDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 20),
        ),
      ),
    );
  }

  Widget _buildPremiumFormateurCard(dynamic formateur, int index, bool isExpanded, bool isMe) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFFFFDE7) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isMe ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
          width: isMe ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _expandedFormateurId = isExpanded ? null : formateur['id'];
              });
            },
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF8FAFC), width: 2),
                          image: formateur['image'] != null
                              ? DecorationImage(
                                  image: NetworkImage(
                                    AppConstants.getMediaUrl(formateur['image']),
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: formateur['image'] == null
                            ? Center(
                                child: Text(
                                  '${formateur['prenom']?[0] ?? ''}${formateur['nom']?[0] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        top: -8,
                        left: -8,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == 0 ? const Color(0xFFFACC15) 
                                : index == 1 ? const Color(0xFFE2E8F0) 
                                : index == 2 ? const Color(0xFFB45309) 
                                : const Color(0xFFF1F5F9),
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: index == 0 ? Colors.black : (index <= 2 ? Colors.white : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${formateur['prenom']} ${formateur['nom']}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFACC15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'VOUS',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.groups_rounded, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 6),
                            Text(
                              'Équipe de ${formateur['total_stagiaires']} Apprenti${formateur['total_stagiaires'] > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(formateur['total_points'] ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} PTS TOTAL',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFACC15),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isExpanded ? const Color(0xFFFACC15) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: isExpanded ? Colors.black : const Color(0xFF94A3B8),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC).withOpacity(0.5),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              padding: const EdgeInsets.all(20),
              child: _buildPremiumStagiairesGrid(formateur['stagiaires'] ?? []),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumStagiairesGrid(List<dynamic> stagiaires) {
    if (stagiaires.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'AUCUN DÉFI RELEVÉ PAR CETTE ÉQUIPE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 350 ? 2 : 1;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(stagiaires.length, (index) {
            final stagiaire = stagiaires[index];
            return Container(
              width: (constraints.maxWidth - (crossAxisCount > 1 ? 12 : 0)) / crossAxisCount,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      image: stagiaire['image'] != null
                          ? DecorationImage(
                              image: NetworkImage(
                                AppConstants.getMediaUrl(stagiaire['image']),
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: stagiaire['image'] == null
                        ? Center(
                            child: Text(
                              '${stagiaire['prenom']?[0] ?? ''}${stagiaire['nom']?[0] ?? ''}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFCBD5E1),
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${(stagiaire['points'] ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} PTS',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFACC15),
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

  Widget _buildPeriodButton(String id, String label) {
    final isSelected = _period == id;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _period = id);
          _fetchRanking();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))
            ] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF64748B),
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
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
