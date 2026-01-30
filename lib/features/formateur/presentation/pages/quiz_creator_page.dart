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
    final filtered = _quizzes.where((q) {
      final status = (q['status'] ?? '').toString().toLowerCase();
      final niveau = (q['niveau'] ?? '').toString().toLowerCase();
      final formationId = (q['formation_id'] ?? '').toString();
      
      final okStatus = _filterStatus.isEmpty || status == _filterStatus.toLowerCase();
      final okNiveau = _filterNiveau.isEmpty || niveau.contains(_filterNiveau.toLowerCase());
      final okFormation = _filterFormationId.isEmpty || formationId == _filterFormationId;
      
      return okStatus && okNiveau && okFormation;
    }).toList();

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final q in filtered) {
      final key = (q['formation_id'] ?? 'none').toString();
      grouped.putIfAbsent(key, () => []).add(q);
    }

    return Scaffold(
      backgroundColor: FormateurTheme.background,
      appBar: AppBar(
        title: const Text('Atelier Quiz'),
        backgroundColor: Colors.white,
        foregroundColor: FormateurTheme.textPrimary,
        elevation: 0,
        centerTitle: false,
        leading: Navigator.canPop(context) 
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FormateurTheme.accent))
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: FormateurTheme.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildPremiumHeader(),
                    if (_quizzes.isEmpty)
                      _buildEmptyState()
                    else
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                             ...grouped.keys.map((key) => _buildFormationGroup(key, grouped[key]!)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createQuiz,
        backgroundColor: FormateurTheme.textPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded, color: FormateurTheme.accent, size: 24),
        label: const Text('Nouveau Quiz', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
                const Icon(Icons.architecture_rounded, size: 12, color: FormateurTheme.accentDark),
                const SizedBox(width: 8),
                Text(
                  'Atelier de conception',
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
            'Laboratoire Quiz',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: FormateurTheme.textPrimary,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Créez et gérez vos évaluations pédagogiques avec précision.",
            style: TextStyle(
              color: FormateurTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          _buildFiltersSection(),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
           _buildFilterDropdown(
            hint: 'Formation',
            value: _filterFormationId.isEmpty ? null : _filterFormationId,
            items: [
               const DropdownMenuItem(value: '', child: Text('Toutes les formations', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900))),
               ..._formations.map((f) => DropdownMenuItem(value: f['id'].toString(), child: Text((f['nom'] ?? f['titre'] ?? '').toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)))),
            ],
            onChanged: (v) => setState(() => _filterFormationId = v ?? ''),
          ),
          const SizedBox(width: 12),
           _buildFilterDropdown(
            hint: 'Statut',
            value: _filterStatus.isEmpty ? null : _filterStatus,
            items: [
               const DropdownMenuItem(value: '', child: Text('Tous les statuts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900))),
               const DropdownMenuItem(value: 'actif', child: Text('Actif', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900))),
               const DropdownMenuItem(value: 'brouillon', child: Text('Brouillon', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900))),
               const DropdownMenuItem(value: 'archive', child: Text('Archivé', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900))),
            ],
            onChanged: (v) => setState(() => _filterStatus = v ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({required String hint, required String? value, required List<DropdownMenuItem<String>> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: FormateurTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FormateurTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: FormateurTheme.textTertiary)),
          icon: const Icon(Icons.expand_more_rounded, size: 18, color: FormateurTheme.accent),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFormationGroup(String key, List<Map<String, dynamic>> quizzes) {
    String formationTitle = 'Sans formation';
    if (key != 'none' && key.isNotEmpty) {
      final f = _formations.firstWhere((f) => f['id'].toString() == key, orElse: () => {});
      formationTitle = (f['nom'] ?? f['titre'] ?? 'Formation #$key').toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(formationTitle, style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        ),
        ...quizzes.map((q) => _buildQuizCard(q)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz) {
    final status = (quiz['status'] ?? 'brouillon').toString();
    final statusColor = status == 'actif' ? FormateurTheme.success : status == 'archive' ? FormateurTheme.textTertiary : FormateurTheme.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: FormateurTheme.premiumCardDecoration,
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => QuizDetailPage(quizId: quiz['id']))).then((_) => _loadQuizzes()),
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Icon(Icons.assignment_rounded, color: statusColor, size: 24),
        ),
        title: Text(quiz['titre']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: FormateurTheme.textPrimary, letterSpacing: -0.2)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
               _buildCardMetric(Icons.help_outline_rounded, '${quiz['nb_questions'] ?? 0}'),
               const SizedBox(width: 16),
               _buildCardMetric(Icons.timer_outlined, '${quiz['duree'] ?? 0}m'),
               const Spacer(),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                 child: Text(status, style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
               ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: FormateurTheme.background, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.chevron_right_rounded, color: FormateurTheme.border),
        ),
      ),
    );
  }

  Widget _buildCardMetric(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: FormateurTheme.textTertiary),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: FormateurTheme.textSecondary)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: FormateurTheme.border)),
            child: const Icon(Icons.quiz_outlined, size: 48, color: FormateurTheme.border),
          ),
          const SizedBox(height: 24),
          const Text('Votre atelier est vide', style: TextStyle(color: FormateurTheme.textTertiary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
