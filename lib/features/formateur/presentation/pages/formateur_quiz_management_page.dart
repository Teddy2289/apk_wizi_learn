import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/quiz_model.dart';
import 'package:wizi_learn/features/formateur/data/repositories/quiz_repository.dart';
import 'package:wizi_learn/features/formateur/data/repositories/formation_management_repository.dart';
import 'package:wizi_learn/features/formateur/data/models/formation_management_model.dart';
import 'package:wizi_learn/features/formateur/presentation/pages/quiz_detail_page.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';

class FormateurQuizManagementPage extends StatefulWidget {
  const FormateurQuizManagementPage({super.key});

  @override
  State<FormateurQuizManagementPage> createState() =>
      _FormateurQuizManagementPageState();
}

class _FormateurQuizManagementPageState
    extends State<FormateurQuizManagementPage> {
  late final QuizRepository _quizRepository;
  late final FormationManagementRepository _formationRepository;

  List<Quiz> _quizzes = [];
  List<FormationWithStats> _formations = [];
  bool _isLoading = true;

  // Filters
  String _searchQuery = '';
  String? _selectedStatus;
  int? _selectedFormationId;
  String? _selectedNiveau;

  // Expanded formations tracking
  final Map<String, bool> _expandedFormations = {};

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _quizRepository = QuizRepository(apiClient: apiClient);
    _formationRepository = FormationManagementRepository(apiClient: apiClient);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final quizzes = await _quizRepository.getAllQuizzes(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _selectedStatus,
        formationId: _selectedFormationId,
      );
      final formations = await _formationRepository.getAvailableFormations();

      setState(() {
        _quizzes = quizzes;
        _formations = formations;
        // Auto-expand all formations
        for (var quiz in quizzes) {
          final key = quiz.formationId?.toString() ?? 'unassigned';
          _expandedFormations[key] = true;
        }
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, List<Quiz>> get _groupedQuizzes {
    var filteredQuizzes = _quizzes;

    // Apply level filter locally
    if (_selectedNiveau != null && _selectedNiveau!.isNotEmpty) {
      filteredQuizzes = filteredQuizzes
          .where((q) => q.niveau.toLowerCase() == _selectedNiveau!.toLowerCase())
          .toList();
    }

    final groups = <String, List<Quiz>>{};
    for (var quiz in filteredQuizzes) {
      final key = quiz.formationId?.toString() ?? 'unassigned';
      groups.putIfAbsent(key, () => []).add(quiz);
    }
    return groups;
  }

  String _getFormationName(String key) {
    if (key == 'unassigned') return 'Divers / Non assignés';
    final formation = _formations.firstWhere(
      (f) => f.id.toString() == key,
      orElse: () => FormationWithStats(
        id: int.tryParse(key) ?? 0,
        titre: 'Formation #$key',
        categorie: '',
        nbStagiaires: 0,
        nbVideos: 0,
        dureeEstimee: 0,
      ),
    );
    return formation.titre;
  }

  Widget _buildStatusBadge(String status) {
    final s = status.toLowerCase();
    Color bgColor, textColor;

    switch (s) {
      case 'actif':
      case 'active':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        break;
      case 'brouillon':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        break;
      case 'inactif':
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
    }

    final displayText = s == 'actif' || s == 'active' ? 'Validé' :
                       s == 'brouillon' ? 'En attente' : s;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        displayText.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showCreateQuizDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    int duree = 30;
    String niveau = 'débutant';
    int? formationId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(56)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(40, 64, 40, 40),
                  decoration: const BoxDecoration(
                    color: FormateurTheme.accent,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(56)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'CRÉER UN NOUVEAU QUIZ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PARAMÉTREZ VOTRE ÉVALUATION INTERACTIF',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Form
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(56)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormField(
                        label: 'TITRE DU QUIZ',
                        child: TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: 'Ex: Maîtrise de React hooks',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            contentPadding: const EdgeInsets.all(24),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              label: 'NIVEAU',
                              child: DropdownButtonFormField<String>(
                                value: niveau,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                ),
                                items: ['débutant', 'intermédiaire', 'avancé']
                                    .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                                    .toList(),
                                onChanged: (v) => setDialogState(() => niveau = v!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFormField(
                              label: 'DURÉE (MIN)',
                              child: TextFormField(
                                initialValue: duree.toString(),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  contentPadding: const EdgeInsets.all(24),
                                ),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                onChanged: (v) => duree = int.tryParse(v) ?? 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        label: 'FORMATION ASSOCIÉE',
                        child: DropdownButtonFormField<int?>(
                          value: formationId,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Sélectionner une formation...')),
                            ..._formations.map((f) => DropdownMenuItem(value: f.id, child: Text(f.titre))),
                          ],
                          onChanged: (v) => setDialogState(() => formationId = v),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (titleController.text.isEmpty) return;

                            final created = await _quizRepository.createQuiz({
                              'titre': titleController.text,
                              'description': descriptionController.text,
                              'duree': duree,
                              'niveau': niveau,
                              'formation_id': formationId,
                            });

                            if (created != null && mounted) {
                              Navigator.pop(context);
                              _loadData();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FormateurTheme.accent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            elevation: 8,
                          ),
                          child: const Text(
                            'GÉNÉRER LE MODULE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade400,
              letterSpacing: 1.5,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Future<void> _deleteQuiz(int quizId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce quiz ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _quizRepository.deleteQuiz(quizId);
      if (success && mounted) {
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          final horizontalPadding = isMobile ? 12.0 : 48.0;

          return Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  isMobile ? 32 : 64,
                  horizontalPadding,
                  isMobile ? 24 : 48,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: FormateurTheme.accent.withOpacity(0.1),
                        border: Border.all(color: FormateurTheme.accent.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, size: 12, color: FormateurTheme.accent),
                          const SizedBox(width: 8),
                          const Text(
                            'Atelier de Quiz',
                            style: TextStyle(
                              color: FormateurTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text.rich(
                      TextSpan(
                        text: 'Gestion des ',
                        style: TextStyle(
                          fontSize: isMobile ? 28 : 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Quiz',
                            style: TextStyle(color: FormateurTheme.accent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Consultez et organisez vos banques de questions par formation.',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (isMobile)
                      Column(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Rechercher un quiz...',
                              prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: BorderSide(color: Colors.grey.shade100),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: BorderSide(color: Colors.grey.shade100),
                              ),
                              contentPadding: const EdgeInsets.all(20),
                            ),
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                              _loadData();
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int?>(
                            isExpanded: true,
                            value: _selectedFormationId,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.filter_list, color: Colors.grey.shade400),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: BorderSide(color: Colors.grey.shade100),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Toutes les formations')),
                              ..._formations.map((f) => DropdownMenuItem(value: f.id, child: Text(f.titre))),
                            ],
                            onChanged: (v) {
                              setState(() => _selectedFormationId = v);
                              _loadData();
                            },
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showCreateQuizDialog,
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text(
                                'NOUVEAU QUIZ',
                                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FormateurTheme.accent,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                                elevation: 8,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Rechercher un quiz...',
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(32),
                                  borderSide: BorderSide(color: Colors.grey.shade100),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(32),
                                  borderSide: BorderSide(color: Colors.grey.shade100),
                                ),
                                contentPadding: const EdgeInsets.all(24),
                              ),
                              onChanged: (value) {
                                setState(() => _searchQuery = value);
                                _loadData();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              value: _selectedFormationId,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.filter_list, color: Colors.grey.shade400),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(32),
                                  borderSide: BorderSide(color: Colors.grey.shade100),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Toutes les formations')),
                                ..._formations.map((f) => DropdownMenuItem(value: f.id, child: Text(f.titre))),
                              ],
                              onChanged: (v) {
                                setState(() => _selectedFormationId = v);
                                _loadData();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _showCreateQuizDialog,
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text(
                              'NOUVEAU QUIZ',
                              style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FormateurTheme.accent,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                              elevation: 8,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _groupedQuizzes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(48),
                                    border: Border.all(color: Colors.grey.shade100),
                                  ),
                                  child: Icon(Icons.inbox, size: 40, color: Colors.grey.shade200),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Aucun quiz disponible',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'UTILISEZ LE BOUTON "NOUVEAU QUIZ" POUR COMMENCER.',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade400,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: EdgeInsets.all(isMobile ? 12 : 24),
                            children: _groupedQuizzes.entries.map((entry) {
                              final key = entry.key;
                              final quizzes = entry.value;
                              final isExpanded = _expandedFormations[key] ?? true;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 24 : 40)),
                                elevation: 4,
                                shadowColor: Colors.grey.shade200,
                                child: Column(
                                  children: [
                                    // Formation Header
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _expandedFormations[key] = !isExpanded;
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(isMobile ? 16 : 40),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50.withOpacity(0.8),
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(isMobile ? 24 : 40)),
                                          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: isMobile ? 40 : 48,
                                              height: isMobile ? 40 : 48,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(isMobile ? 12 : 20),
                                                border: Border.all(color: Colors.grey.shade200),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  _getFormationName(key).isNotEmpty ? _getFormationName(key)[0] : '?',
                                                  style: TextStyle(
                                                    fontSize: isMobile ? 16 : 18,
                                                    fontWeight: FontWeight.w900,
                                                    color: FormateurTheme.accent,
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
                                                    _getFormationName(key),
                                                    style: TextStyle(
                                                      fontSize: isMobile ? 14 : 16,
                                                      fontWeight: FontWeight.w900,
                                                      color: Colors.black87,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: FormateurTheme.accent.withOpacity(0.05),
                                                      border: Border.all(
                                                        color: FormateurTheme.accent.withOpacity(0.2),
                                                      ),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      '${quizzes.length} ${quizzes.length > 1 ? "Quizzes" : "Quiz"}',
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w700,
                                                        color: FormateurTheme.accent,
                                                        letterSpacing: 1.2,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              isExpanded ? Icons.expand_less : Icons.expand_more,
                                              color: Colors.grey.shade400,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Quiz List
                                    if (isExpanded)
                                      ...quizzes.map((quiz) => _buildQuizRow(quiz, isMobile)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuizRow(Quiz quiz, bool isMobile) {
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.titre,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quiz.description ?? 'Apprentissage interactif',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(quiz.status),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    quiz.niveau,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '${quiz.duree}m',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: FormateurTheme.accent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${quiz.nbQuestions} Qs',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: FormateurTheme.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizDetailPage(quizId: quiz.id),
                      ),
                    ).then((_) => _loadData());
                  },
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('VOIR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: FormateurTheme.accent),
                ),
                TextButton.icon(
                  onPressed: () => _deleteQuiz(quiz.id),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('SUPPRIMER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade50)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.titre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  quiz.description ?? 'Apprentissage interactif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              quiz.niveau,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildStatusBadge(quiz.status),
          const SizedBox(width: 16),
          Row(
            children: [
              Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                '${quiz.duree}m',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FormateurTheme.accent.withOpacity(0.05),
                  border: Border.all(color: FormateurTheme.accent.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${quiz.nbQuestions} Qs',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: FormateurTheme.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(Icons.visibility, color: Colors.grey.shade200),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizDetailPage(quizId: quiz.id),
                ),
              ).then((_) => _loadData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.grey),
            onPressed: () => _deleteQuiz(quiz.id),
          ),
        ],
      ),
    );
  }
}
