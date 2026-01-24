import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/analytics_model.dart';
import 'package:wizi_learn/features/formateur/data/repositories/analytics_repository.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';
import 'package:intl/intl.dart';

class FormateurSuiviDemandesPage extends StatefulWidget {
  const FormateurSuiviDemandesPage({super.key});

  @override
  State<FormateurSuiviDemandesPage> createState() => _FormateurSuiviDemandesPageState();
}

class _FormateurSuiviDemandesPageState extends State<FormateurSuiviDemandesPage> {
  late final AnalyticsRepository _repository;
  bool _loading = true;
  List<DemandeSuivi> _demandes = [];
  List<DemandeSuivi> _filteredDemandes = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _repository = AnalyticsRepository(apiClient: apiClient);
    _loadData();
    _searchController.addListener(_filterDemandes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await _repository.getDemandesSuivi();
      setState(() {
        _demandes = data;
        _filteredDemandes = data;
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

  void _filterDemandes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDemandes = _demandes.where((d) {
        return d.stagiaireName.toLowerCase().contains(query) ||
               d.formation.toLowerCase().contains(query) ||
               (d.motif?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormateurTheme.background,
      appBar: AppBar(
        title: const Text('Suivi des Demandes'),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un stagiaire...',
                prefixIcon: const Icon(Icons.search, color: FormateurTheme.accent),
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
                  borderSide: const BorderSide(color: FormateurTheme.accent, width: 2),
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
                    child: _filteredDemandes.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredDemandes.length,
                            itemBuilder: (context, index) {
                              return _buildDemandeCard(_filteredDemandes[index]);
                            },
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
          Icon(Icons.assignment_outlined, size: 64, color: FormateurTheme.textTertiary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Aucune demande trouvée',
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

  Widget _buildDemandeCard(DemandeSuivi demande) {
    Color statusColor;
    String statusLabel;

    switch (demande.statut.toLowerCase()) {
      case 'en_attente':
        statusColor = Colors.amber;
        statusLabel = 'EN ATTENTE';
        break;
      case 'valide':
      case 'complete':
        statusColor = FormateurTheme.success;
        statusLabel = 'VALIDÉ';
        break;
      case 'rejete':
      case 'refuse':
        statusColor = FormateurTheme.error;
        statusLabel = 'REJETÉ';
        break;
      default:
        statusColor = FormateurTheme.textTertiary;
        statusLabel = demande.statut.toUpperCase();
    }

    DateTime? date;
    try {
      date = DateTime.parse(demande.date);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FormateurTheme.border),
        boxShadow: FormateurTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: FormateurTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      demande.stagiaireName.isNotEmpty ? demande.stagiaireName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        color: FormateurTheme.accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        demande.stagiaireName,
                        style: const TextStyle(
                          color: FormateurTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      if (date != null)
                        Text(
                          DateFormat('dd MMMM yyyy HH:mm', 'fr_FR').format(date),
                          style: const TextStyle(
                            color: FormateurTheme.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            Row(
              children: [
                const Icon(Icons.school_outlined, size: 16, color: FormateurTheme.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    demande.formation,
                    style: const TextStyle(
                      color: FormateurTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            if (demande.motif != null && demande.motif!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: FormateurTheme.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      demande.motif!,
                      style: const TextStyle(
                        color: FormateurTheme.textTertiary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
