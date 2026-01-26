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
    // Grouping logic
    final groupedDemandes = <int, List<DemandeSuivi>>{};
    for (final d in _filteredDemandes) {
      groupedDemandes.putIfAbsent(d.stagiaireId, () => []).add(d);
    }

    return Scaffold(
      backgroundColor: FormateurTheme.background,
      appBar: AppBar(
        title: const Text('Suivi Demandes'),
        backgroundColor: Colors.white,
        foregroundColor: FormateurTheme.textPrimary,
        elevation: 0,
        centerTitle: false,
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
      body: Column(
        children: [
          _buildPremiumHeader(),
          
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: FormateurTheme.accent))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: FormateurTheme.accent,
                    child: _filteredDemandes.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.all(24),
                            itemCount: groupedDemandes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 24),
                            itemBuilder: (context, index) {
                              final studentId = groupedDemandes.keys.elementAt(index);
                              final studentDemandes = groupedDemandes[studentId]!;
                              return _buildStudentGroupCard(studentDemandes);
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history_edu_rounded, size: 12, color: FormateurTheme.accentDark),
                const SizedBox(width: 8),
                Text(
                  'ADMINISTRATION',
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
            'Inscriptions & Suivi',
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
            "Gérez les demandes d'accès aux formations de vos stagiaires.",
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
        controller: _searchController,
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

  Widget _buildStudentGroupCard(List<DemandeSuivi> demandes) {
    final first = demandes.first;
    return Container(
      decoration: FormateurTheme.premiumCardDecoration,
      child: Column(
        children: [
          // Student Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: FormateurTheme.accent.withOpacity(0.1),
                  child: Text(
                    first.stagiaireName[0].toUpperCase(),
                    style: const TextStyle(color: FormateurTheme.accentDark, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        first.stagiaireName.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: FormateurTheme.textPrimary),
                      ),
                      Text(
                        '${demandes.length} ${demandes.length > 1 ? 'DEMANDES' : 'DEMANDE'}',
                        style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: FormateurTheme.border),
          // Demands List
          ...demandes.map((d) => _buildDemandeListItem(d)),
        ],
      ),
    );
  }

  Widget _buildDemandeListItem(DemandeSuivi demande) {
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
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: FormateurTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  demande.formation.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: FormateurTheme.textPrimary, letterSpacing: -0.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 12, color: FormateurTheme.textTertiary),
              const SizedBox(width: 6),
              Text(
                date != null ? DateFormat('dd/MM/yyyy HH:mm').format(date) : demande.date,
                style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (demande.motif != null && demande.motif!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: FormateurTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                demande.motif!,
                style: const TextStyle(color: FormateurTheme.textSecondary, fontSize: 11, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
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
            child: const Icon(Icons.assignment_outlined, size: 48, color: FormateurTheme.border),
          ),
          const SizedBox(height: 16),
          const Text(
            'AUCUNE DEMANDE TROUVÉE',
            style: TextStyle(color: FormateurTheme.textTertiary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }
}
