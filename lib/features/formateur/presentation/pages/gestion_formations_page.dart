import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/formation_management_model.dart';
import 'package:wizi_learn/features/formateur/data/repositories/formation_management_repository.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';

class GestionFormationsPage extends StatefulWidget {
  const GestionFormationsPage({super.key});

  @override
  State<GestionFormationsPage> createState() => _GestionFormationsPageState();
}

class _GestionFormationsPageState extends State<GestionFormationsPage> {
  late final FormationManagementRepository _repository;
  
  List<FormationWithStats> _formations = [];
  List<FormationWithStats> _filteredFormations = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _repository = FormationManagementRepository(
      apiClient: ApiClient(
        dio: Dio(),
        storage: const FlutterSecureStorage(),
      ),
    );
    _loadFormations();
  }

  Future<void> _loadFormations() async {
    setState(() => _loading = true);
    try {
      final formations = await _repository.getAvailableFormations();
      setState(() {
        _formations = formations;
        _filteredFormations = formations;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: FormateurTheme.error),
        );
      }
    }
  }

  void _filterFormations(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredFormations = _formations;
      } else {
        _filteredFormations = _formations
            .where((f) =>
                f.titre.toLowerCase().contains(query.toLowerCase()) ||
                f.categorie.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _showAssignDialog(FormationWithStats formation) async {
    final unassigned = await _repository.getUnassignedStagiaires(formation.id);
    
    if (!mounted) return;
    
    if (unassigned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tous les stagiaires sont déjà assignés à cette formation'), backgroundColor: FormateurTheme.textSecondary),
      );
      return;
    }

    final selected = <int>[];
    DateTime? dateDebut;
    DateTime? dateFin;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(
            'Assigner: ${formation.titre}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SÉLECTIONNEZ LES APPRENANTS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: FormateurTheme.textTertiary, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: unassigned.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: FormateurTheme.border),
                    itemBuilder: (context, index) {
                      final stagiaire = unassigned[index];
                      final isSelected = selected.contains(stagiaire.id);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: FormateurTheme.accentDark,
                        title: Text(stagiaire.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(stagiaire.email, style: const TextStyle(color: FormateurTheme.textSecondary, fontSize: 12)),
                        value: isSelected,
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              selected.add(stagiaire.id);
                            } else {
                              selected.remove(stagiaire.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: FormateurTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: selected.isEmpty
                  ? null
                  : () async {
                      Navigator.pop(context);
                      final success = await _repository.assignFormation(
                        formationId: formation.id,
                        stagiaireIds: selected,
                        dateDebut: dateDebut,
                        dateFin: dateFin,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? '${selected.length} stagiaire(s) assigné(s)'
                                : 'Erreur d\'assignation'),
                            backgroundColor: success ? FormateurTheme.success : FormateurTheme.error,
                          ),
                        );
                        if (success) _loadFormations();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: FormateurTheme.accentDark,
                foregroundColor: Colors.white,
                disabledBackgroundColor: FormateurTheme.textTertiary.withOpacity(0.3),
              ),
              child: const Text('Assigner'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFormationDetails(FormationWithStats formation) async {
    final stagiaires = await _repository.getStagiairesByFormation(formation.id);
    final stats = await _repository.getFormationStats(formation.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: FormateurTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                formation.titre.toUpperCase(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: FormateurTheme.textPrimary, letterSpacing: -0.5),
              ),
              const SizedBox(height: 24),
              // Stats Cards
              Row(
                children: [
                  _StatCard('TOTAL', stats.totalStagiaires.toString(), Colors.blue),
                  const SizedBox(width: 12),
                  _StatCard('COMPLÉTÉ', stats.completed.toString(), FormateurTheme.success),
                  const SizedBox(width: 12),
                  _StatCard('EN COURS', stats.inProgress.toString(), FormateurTheme.orangeAccent),
                ],
              ),
              const SizedBox(height: 32),
              const Text('STAGIAIRES INSCRITS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: FormateurTheme.textTertiary, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: stagiaires.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final stagiaire = stagiaires[index];
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: FormateurTheme.border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: stagiaire.isActive ? FormateurTheme.success.withOpacity(0.1) : FormateurTheme.background,
                          backgroundImage: stagiaire.avatar != null && stagiaire.avatar!.isNotEmpty
                              ? NetworkImage(AppConstants.getUserImageUrl(stagiaire.avatar!))
                              : null,
                          child: (stagiaire.avatar == null || stagiaire.avatar!.isEmpty)
                              ? Text(
                                  stagiaire.prenom[0].toUpperCase(),
                                  style: TextStyle(
                                    color: stagiaire.isActive ? FormateurTheme.success : FormateurTheme.textTertiary,
                                    fontWeight: FontWeight.bold
                                  ),
                                )
                              : null,
                        ),
                        title: Text(stagiaire.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: stagiaire.progress / 10,
                                backgroundColor: FormateurTheme.background,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  stagiaire.progress == 10
                                      ? FormateurTheme.success
                                      : FormateurTheme.orangeAccent,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          '${stagiaire.progress * 10}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: FormateurTheme.textPrimary),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormateurTheme.background,
      appBar: AppBar(
        title: const Text('Mes Formations'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
            color: FormateurTheme.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            fontFamily: 'Montserrat'
        ),
        foregroundColor: FormateurTheme.textPrimary,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: FormateurTheme.cardShadow,
                border: Border.all(color: FormateurTheme.border),
              ),
              child: TextField(
                onChanged: _filterFormations,
                decoration: const InputDecoration(
                  hintText: 'Rechercher une formation...',
                  hintStyle: TextStyle(color: FormateurTheme.textTertiary, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: FormateurTheme.textTertiary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                style: const TextStyle(color: FormateurTheme.textPrimary),
              ),
            ),
          ),
          // Formations List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: FormateurTheme.accent))
                : _filteredFormations.isEmpty
                    ? const Center(child: Text('Aucune formation trouvée', style: TextStyle(color: FormateurTheme.textTertiary)))
                    : RefreshIndicator(
                        onRefresh: _loadFormations,
                        color: FormateurTheme.accent,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: _filteredFormations.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final formation = _filteredFormations[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: FormateurTheme.border),
                                boxShadow: FormateurTheme.cardShadow,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showFormationDetails(formation),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    formation.titre,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w800,
                                                      color: FormateurTheme.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    formation.categorie.toUpperCase(),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: FormateurTheme.textTertiary,
                                                      letterSpacing: 1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.people_outline, size: 16, color: Colors.blue),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${formation.nbStagiaires}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.blue,
                                                      fontSize: 12
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Icon(Icons.video_library_outlined, size: 16, color: FormateurTheme.textSecondary),
                                            const SizedBox(width: 6),
                                            Text('${formation.nbVideos} vidéos', style: const TextStyle(fontSize: 12, color: FormateurTheme.textSecondary, fontWeight: FontWeight.w500)),
                                            const SizedBox(width: 20),
                                            Icon(Icons.schedule_outlined, size: 16, color: FormateurTheme.textSecondary),
                                            const SizedBox(width: 6),
                                            Text('${formation.dureeEstimee}h', style: const TextStyle(fontSize: 12, color: FormateurTheme.textSecondary, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () => _showFormationDetails(formation),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: FormateurTheme.textPrimary,
                                                  side: const BorderSide(color: FormateurTheme.border),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                                child: const Text('DÉTAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => _showAssignDialog(formation),
                                                icon: const Icon(Icons.add, size: 18),
                                                label: const Text('ASSIGNER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: FormateurTheme.accentDark,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  elevation: 0,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: FormateurTheme.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
