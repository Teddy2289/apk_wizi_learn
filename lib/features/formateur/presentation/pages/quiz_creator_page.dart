import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';
import 'package:wizi_learn/features/formateur/presentation/pages/quiz_detail_page.dart';

class QuizCreatorPage extends StatefulWidget {
  const QuizCreatorPage({super.key});

  @override
  State<QuizCreatorPage> createState() => _QuizCreatorPageState();
}

class _QuizCreatorPageState extends State<QuizCreatorPage> {
  late final ApiClient _apiClient;
  List<Map<String, dynamic>> _quizzes = [];
  List<Map<String, dynamic>> _formations = [];
  bool _loading = true;

  // Filters
  String _filterFormationId = '';
  String _filterStatus = '';
  String _filterNiveau = '';

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final responses = await Future.wait([
        _apiClient.get('/formateur/quizzes'),
        _apiClient.get('/formateur/formations-list'),
      ]);
      
      setState(() {
        _quizzes = List<Map<String, dynamic>>.from(responses[0].data['quizzes'] ?? []);
        _formations = List<Map<String, dynamic>>.from(responses[1].data['formations'] ?? []);
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

  Future<void> _loadQuizzes() async => _loadAll();

  Future<void> _createQuiz() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String niveau = 'debutant';
    int duree = 30;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text('Créer un quiz', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Titre',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: FormateurTheme.background,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description (optionnel)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: FormateurTheme.background,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: niveau,
                  decoration: InputDecoration(
                    labelText: 'Niveau',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: FormateurTheme.background,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'debutant', child: Text('Débutant')),
                    DropdownMenuItem(value: 'intermediaire', child: Text('Intermédiaire')),
                    DropdownMenuItem(value: 'avance', child: Text('Avancé')),
                  ],
                  onChanged: (v) => setDialogState(() => niveau = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Durée (minutes)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: FormateurTheme.background,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => duree = int.tryParse(v) ?? 30,
                  controller: TextEditingController(text: duree.toString()),
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
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(context);

                try {
                  await _apiClient.post('/formateur/quizzes', data: {
                    'titre': titleCtrl.text,
                    'description': descCtrl.text,
                    'duree': duree,
                    'niveau': niveau,
                    'status': 'brouillon',
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Quiz créé'), backgroundColor: FormateurTheme.success),
                    );
                  }
                  _loadQuizzes();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e'), backgroundColor: FormateurTheme.error),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FormateurTheme.accentDark,
                foregroundColor: Colors.white,
              ),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteQuiz(int quizId) async {
    try {
      await _apiClient.delete('/formateur/quizzes/$quizId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz supprimé'), backgroundColor: FormateurTheme.success),
        );
      }
      _loadQuizzes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: FormateurTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Apply filters then group by formation
    final filtered = _quizzes.where((q) {
      final status = (q['status'] ?? '').toString().toLowerCase();
      final niveau = (q['niveau'] ?? '').toString().toLowerCase();
      final formationId = (q['formation_id'] ?? '').toString();
      
      final okStatus = _filterStatus.isEmpty || status == _filterStatus.toLowerCase();
      final okNiveau = _filterNiveau.isEmpty || niveau.contains(_filterNiveau.toLowerCase());
      final okFormation = _filterFormationId.isEmpty || formationId == _filterFormationId;
      
      return okStatus && okNiveau && okFormation;
    }).toList();

    // Grouping for the list display
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final q in filtered) {
      final key = (q['formation_id'] ?? 'none').toString();
      grouped.putIfAbsent(key, () => []).add(q);
    }

    String formationName(String id) {
      if (id == 'none' || id.isEmpty) return 'Sans formation';
      final formation = _formations.firstWhere(
        (f) => f['id'].toString() == id,
        orElse: () => {'titre': 'Formation #$id'},
      );
      return (formation['nom'] ?? formation['titre'] ?? 'Formation #$id').toString();
    }

    return Scaffold(
      backgroundColor: FormateurTheme.background,
      appBar: AppBar(
        title: const Text('Gestion des Quiz'),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FormateurTheme.accent))
          : _quizzes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.quiz_outlined, size: 64, color: FormateurTheme.textTertiary),
                      const SizedBox(height: 16),
                      const Text('Aucun quiz créé', style: TextStyle(color: FormateurTheme.textSecondary, fontSize: 16)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _createQuiz,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('CRÉER LE PREMIER QUIZ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FormateurTheme.accentDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: grouped.keys.length + 1,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    // First item: filters UI
                    if (index == 0) {
                      return _Filters(
                        filterStatus: _filterStatus,
                        filterNiveau: _filterNiveau,
                        filterFormationId: _filterFormationId,
                        onStatusChanged: (v) => setState(() => _filterStatus = v),
                        onNiveauChanged: (v) => setState(() => _filterNiveau = v),
                        onFormationChanged: (v) => setState(() => _filterFormationId = v),
                        formations: _formations,
                      );
                    }

                    final key = grouped.keys.elementAt(index - 1);
                    final items = grouped[key]!;
                    final label = formationName(key);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4),
                          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: FormateurTheme.textPrimary)),
                        ),
                        ...items.map((quiz) {
                          final status = quiz['status'] ?? 'brouillon';
                          final statusColor = status == 'actif'
                              ? FormateurTheme.success
                              : status == 'archive'
                                  ? FormateurTheme.textTertiary
                                  : FormateurTheme.orangeAccent;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: FormateurTheme.border),
                              boxShadow: FormateurTheme.cardShadow,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                quiz['titre'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: FormateurTheme.textPrimary),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    _InfoChip(icon: Icons.help_outline, label: '${quiz['nb_questions'] ?? 0} questions'),
                                    _InfoChip(icon: Icons.timer_outlined, label: '${quiz['duree'] ?? 0} min'),
                                    _StatusChip(status: status.toString(), color: statusColor),
                                  ],
                                ),
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.assignment_outlined, color: statusColor),
                              ),
                              trailing: PopupMenuButton(
                                icon: const Icon(Icons.more_vert, color: FormateurTheme.textSecondary),
                                color: Colors.white,
                                elevation: 4,
                                surfaceTintColor: Colors.white,
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility_outlined, size: 20, color: FormateurTheme.textPrimary),
                                        SizedBox(width: 12),
                                        Text('Voir détails'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, size: 20, color: FormateurTheme.error),
                                        SizedBox(width: 12),
                                        Text('Supprimer', style: TextStyle(color: FormateurTheme.error)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deleteQuiz(quiz['id']);
                                  } else if (value == 'view') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuizDetailPage(quizId: quiz['id']),
                                      ),
                                    ).then((_) => _loadQuizzes());
                                  }
                                },
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuizDetailPage(quizId: quiz['id']),
                                  ),
                                ).then((_) => _loadQuizzes());
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createQuiz,
        backgroundColor: FormateurTheme.accentDark,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: FormateurTheme.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: FormateurTheme.textSecondary)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final String filterStatus;
  final String filterNiveau;
  final String filterFormationId;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onNiveauChanged;
  final ValueChanged<String> onFormationChanged;
  final List<Map<String, dynamic>> formations;

  const _Filters({
    required this.filterStatus,
    required this.filterNiveau,
    required this.filterFormationId,
    required this.onStatusChanged,
    required this.onNiveauChanged,
    required this.onFormationChanged,
    required this.formations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FormateurTheme.border),
        boxShadow: FormateurTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filtres', style: TextStyle(fontWeight: FontWeight.bold, color: FormateurTheme.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  value: filterFormationId.isEmpty ? null : filterFormationId,
                  hint: const Text('Formation'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: FormateurTheme.border)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Toutes les formations')),
                    ...formations.map((f) => DropdownMenuItem(
                      value: f['id'].toString(), 
                      child: Text(f['nom'] ?? f['titre'] ?? 'Formation #${f['id']}')
                    )),
                  ],
                  onChanged: (v) => onFormationChanged(v ?? ''),
                ),
              ),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  value: filterNiveau.isEmpty ? null : filterNiveau,
                  hint: const Text('Niveau'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: FormateurTheme.border)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Tous')),
                    DropdownMenuItem(value: 'débutant', child: Text('Débutant')),
                    DropdownMenuItem(value: 'intermédiaire', child: Text('Intermédiaire')),
                    DropdownMenuItem(value: 'avancé', child: Text('Avancé')),
                  ],
                  onChanged: (v) => onNiveauChanged(v ?? ''),
                ),
              ),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  value: filterStatus.isEmpty ? null : filterStatus,
                  hint: const Text('Statut'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: FormateurTheme.border)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Tous')),
                    DropdownMenuItem(value: 'actif', child: Text('Actif')),
                    DropdownMenuItem(value: 'brouillon', child: Text('Brouillon')),
                    DropdownMenuItem(value: 'inactif', child: Text('Inactif')),
                    DropdownMenuItem(value: 'archive', child: Text('Archivé')),
                  ],
                  onChanged: (v) => onStatusChanged(v ?? ''),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
