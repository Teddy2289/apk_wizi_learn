import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';

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
  List<dynamic> _formations = [];
  String _selectedFormationId = 'global';
  String _period = 'all';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Load formations first if empty
      if (_formations.isEmpty) {
        final formationsResponse = await _apiClient.get('/formateur/formations');
        final formationsData = formationsResponse.data;
        if (mounted) {
          setState(() {
            _formations = (formationsData['formations'] as List?) ?? [];
          });
        }

      }

      // Load ranking
      final endpoint = _selectedFormationId == 'global'
          ? '/formateur/classement/mes-stagiaires'
          : '/formateur/classement/formation/$_selectedFormationId';
      
      final response = await _apiClient.get(endpoint, queryParameters: {'period': _period});
      final data = response.data;
      
      if (mounted) {
        setState(() {
          _ranking = data['ranking'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement classement: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormateurTheme.background,
      appBar: AppBar(
        title: const Text('Classement Élite'),
        backgroundColor: Colors.transparent,
        foregroundColor: FormateurTheme.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
            color: FormateurTheme.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            fontFamily: 'Montserrat'
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FormateurTheme.accent))
          : RefreshIndicator(
              color: FormateurTheme.accent,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildFilterSection(),
                    const SizedBox(height: 24),
                    _buildRankingTable(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: FormateurTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: FormateurTheme.accent.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: FormateurTheme.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'HALL OF FAME',
                          style: TextStyle(
                            color: FormateurTheme.accentDark,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Suivez l\'excellence de vos stagiaires en temps réel.',
                    style: TextStyle(
                      color: FormateurTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FormateurTheme.border),
          ),
          child: Row(
            children: [
              _buildPeriodTab('Global', 'all'),
              _buildPeriodTab('Mensuel', 'month'),
              _buildPeriodTab('Hebdo', 'week'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodTab(String label, String value) {
    final isSelected = _period == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _period = value;
            _loadData();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? FormateurTheme.textPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: isSelected ? Colors.white : FormateurTheme.textTertiary,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FormateurTheme.border),
        boxShadow: FormateurTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PÉRIMÈTRE D\'ANALYSE',
            style: TextStyle(
              color: FormateurTheme.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedFormationId,
            decoration: InputDecoration(
              filled: true,
              fillColor: FormateurTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            isExpanded: true, // Fix for long texts
            style: const TextStyle(
              color: FormateurTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              fontSize: 14,
            ),
            items: [
              const DropdownMenuItem(
                value: 'global',
                child: Text('🌍 TOUS MES STAGIAIRES'),
              ),
              ..._formations.map((f) => DropdownMenuItem(
                value: f['id'].toString(),
                child: Text('🎓 ${f['titre']}', overflow: TextOverflow.ellipsis),
              )),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedFormationId = value;
                  _loadData();
                });
              }
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatDetail('COMPÉTITEURS', '${_ranking.length}', Icons.people_outline),
              _buildStatDetail('LEADER', _ranking.isNotEmpty ? '${_ranking.first['total_points']}' : '0', Icons.emoji_events_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: FormateurTheme.textTertiary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: FormateurTheme.textTertiary,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: FormateurTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRankingTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FormateurTheme.border),
        boxShadow: FormateurTheme.cardShadow,
      ),
      child: _ranking.isEmpty 
        ? const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: Text("Aucune donnée disponible")),
          )
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _ranking.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: FormateurTheme.border),
            itemBuilder: (context, index) {
              final stagiaire = _ranking[index];
              return _buildRankingRow(stagiaire, index + 1);
            },
          ),
    );
  }

  Widget _buildRankingRow(dynamic stagiaire, int index) {
    // Use rank from API if available, otherwise use index + 1
    final int rank = stagiaire['rank'] != null ? int.parse(stagiaire['rank'].toString()) : index;
    final bool isTop3 = rank <= 3;
    final String? imagePath = stagiaire['image'] ?? stagiaire['avatar'];

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isTop3 ? _getRankGradient(rank) : null,
              color: isTop3 ? null : FormateurTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: isTop3 ? null : Border.all(color: FormateurTheme.border),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: isTop3 ? Colors.white : FormateurTheme.textSecondary,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User Avatar
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isTop3 ? _getRankColor(rank) : FormateurTheme.border,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: FormateurTheme.background,
              backgroundImage: imagePath != null
                  ? NetworkImage(AppConstants.getUserImageUrl(imagePath))
                  : null,
              child: imagePath == null
                  ? Text(
                      (stagiaire['prenom'] as String)[0].toUpperCase(),
                      style: const TextStyle(
                        color: FormateurTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stagiaire['prenom']} ${stagiaire['nom']}',
                  style: const TextStyle(
                    color: FormateurTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  stagiaire['email'] ?? '',
                  style: const TextStyle(
                    color: FormateurTheme.textTertiary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${stagiaire['total_points'] ?? 0}',
                style: const TextStyle(
                  color: FormateurTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Text(
                'XP',
                style: TextStyle(
                  color: FormateurTheme.accentDark,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return FormateurTheme.border;
    }
  }

  LinearGradient _getRankGradient(int rank) {
    switch (rank) {
      case 1:
        return const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]); // Gold
      case 2:
        return LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade500]); // Silver
      case 3:
        return const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFFA0522D)]); // Bronze
      default:
        return const LinearGradient(colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)]);
    }
  }
}
