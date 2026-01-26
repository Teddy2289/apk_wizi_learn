import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/analytics_model.dart';
import 'package:wizi_learn/features/formateur/data/repositories/analytics_repository.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';
import 'package:intl/intl.dart';

class FormateurSuiviParrainagePage extends StatefulWidget {
  const FormateurSuiviParrainagePage({super.key});

  @override
  State<FormateurSuiviParrainagePage> createState() => _FormateurSuiviParrainagePageState();
}

class _FormateurSuiviParrainagePageState extends State<FormateurSuiviParrainagePage> {
  late final AnalyticsRepository _repository;
  bool _loading = true;
  List<ParrainageSuivi> _parrainages = [];
  List<ParrainageSuivi> _filteredParrainages = [];
  final TextEditingController _searchController = TextEditingController();

  int _totalPoints = 0;
  double _totalGains = 0;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _repository = AnalyticsRepository(apiClient: apiClient);
    _loadData();
    _searchController.addListener(_filterParrainages);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await _repository.getParrainageSuivi();
      int points = 0;
      double gains = 0;
      for (var p in data) {
        points += p.points;
        gains += double.tryParse(p.gains) ?? 0;
      }

      setState(() {
        _parrainages = data;
        _filteredParrainages = data;
        _totalPoints = points;
        _totalGains = gains;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: FormateurTheme.error),
        );
      }
    }
  }

  void _filterParrainages() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredParrainages = _parrainages.where((p) {
        return p.filleulName.toLowerCase().contains(query) ||
               (p.parrainName?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormateurTheme.background,
      appBar: AppBar(
        title: const Text('Suivi Parrainage'),
        backgroundColor: Colors.transparent,
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
      body: Column(
        children: [
          _buildStatsHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un filleul...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: FormateurTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: FormateurTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: FormateurTheme.accent))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: FormateurTheme.accent,
                    child: _filteredParrainages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredParrainages.length,
                            itemBuilder: (context, index) {
                              return _buildParrainageCard(_filteredParrainages[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: FormateurTheme.cardShadow,
                border: Border.all(color: FormateurTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    'TOTAL POINTS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _totalPoints.toString(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: FormateurTheme.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: FormateurTheme.cardShadow,
                border: Border.all(color: FormateurTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GAINS (ESTIMÉS)',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_totalGains.toStringAsFixed(0)}€',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_outlined, size: 64, color: FormateurTheme.textTertiary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Aucun parrainage trouvé',
            style: TextStyle(
              color: FormateurTheme.textTertiary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParrainageCard(ParrainageSuivi parrainage) {
    DateTime? date;
    try {
      date = DateTime.parse(parrainage.date);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FormateurTheme.border),
        boxShadow: FormateurTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.person_add_outlined, color: Colors.blue, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parrainage.filleulName,
                        style: const TextStyle(
                          color: FormateurTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Parrain: ${parrainage.parrainName ?? "Inconnu"}',
                        style: const TextStyle(
                          color: FormateurTheme.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${parrainage.points} pts',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${parrainage.gains}€',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (date != null)
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(date),
                    style: const TextStyle(
                      color: FormateurTheme.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: FormateurTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    parrainage.filleulStatut.toUpperCase(),
                    style: const TextStyle(
                      color: FormateurTheme.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
