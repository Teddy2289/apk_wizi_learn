import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/formation_management_model.dart';
import 'package:wizi_learn/features/formateur/data/repositories/formation_management_repository.dart';

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
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
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
    // Load unassigned stagiaires
    final unassigned = await _repository.getUnassignedStagiaires(formation.id);
    
    if (!mounted) return;
    
    if (unassigned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tous les stagiaires sont déjà assignés à cette formation')),
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
          title: Text('Assigner: ${formation.titre}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Sélectionnez les stagiaires:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: unassigned.length,
                    itemBuilder: (context, index) {
                      final stagiaire = unassigned[index];
                      final isSelected = selected.contains(stagiaire.id);
                      return CheckboxListTile(
                        title: Text(stagiaire.fullName),
                        subtitle: Text(stagiaire.email),
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
              child: const Text('Annuler'),
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
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                        if (success) _loadFormations();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF7931E),
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
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formation.titre,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Stats Cards
              Row(
                children: [
                  _StatCard('Total', stats.totalStagiaires.toString(), Colors.blue),
                  const SizedBox(width: 8),
                  _StatCard('Complété', stats.completed.toString(), Colors.green),
                  const SizedBox(width: 8),
                  _StatCard('En cours', stats.inProgress.toString(), Colors.orange),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Stagiaires inscrits:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: stagiaires.length,
                  itemBuilder: (context, index) {
                    final stagiaire = stagiaires[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: stagiaire.isActive ? Colors.green : Colors.grey,
                          child: Text(stagiaire.prenom[0].toUpperCase()),
                        ),
                        title: Text(stagiaire.fullName),
                        subtitle: LinearProgressIndicator(
                          value: stagiaire.progress / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            stagiaire.progress == 100
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        trailing: Text('${stagiaire.progress}%'),
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
      appBar: AppBar(
        title: const Text('Gestion des Formations'),
        backgroundColor: const Color(0xFFF7931E),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _filterFormations,
              decoration: InputDecoration(
                hintText: 'Rechercher une formation...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          // Formations List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFormations.isEmpty
                    ? const Center(child: Text('Aucune formation trouvée'))
                    : RefreshIndicator(
                        onRefresh: _loadFormations,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredFormations.length,
                          itemBuilder: (context, index) {
                            final formation = _filteredFormations[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () => _showFormationDetails(formation),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
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
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  formation.categorie,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.people, size: 16, color: Colors.blue),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${formation.nbStagiaires}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(Icons.video_library, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text('${formation.nbVideos} vidéos'),
                                          const SizedBox(width: 16),
                                          Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text('${formation.dureeEstimee}h'),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _showFormationDetails(formation),
                                              icon: const Icon(Icons.visibility),
                                              label: const Text('Voir détails'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _showAssignDialog(formation),
                                              icon: const Icon(Icons.add),
                                              label: const Text('Assigner'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFF7931E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
