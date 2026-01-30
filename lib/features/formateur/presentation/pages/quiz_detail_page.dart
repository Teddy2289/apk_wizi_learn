import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/quiz_model.dart';
import 'package:wizi_learn/features/formateur/data/repositories/quiz_repository.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';

class QuizDetailPage extends StatefulWidget {
  final int quizId;

  const QuizDetailPage({super.key, required this.quizId});

  @override
  State<QuizDetailPage> createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends State<QuizDetailPage> {
  late final QuizRepository _repository;
  Quiz? _quiz;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = QuizRepository(
      apiClient: ApiClient(dio: Dio(), storage: const FlutterSecureStorage()),
    );
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() => _loading = true);
    try {
      final quiz = await _repository.getQuizById(widget.quizId);
      if (mounted) {
        setState(() {
          _quiz = quiz;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: FormateurTheme.error),
        );
      }
    }
  }

  Future<void> _addQuestion() async {
    final questionCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: '1');
    // Simple QCM: 2 options minimum for now
    List<Map<String, dynamic>> options = [
      {'content': '', 'is_correct': false},
      {'content': '', 'is_correct': false},
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text('Ajouter une question', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionCtrl,
                  decoration: InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: FormateurTheme.background,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pointsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Points',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: FormateurTheme.background,
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Réponses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: FormateurTheme.textTertiary)),
                const SizedBox(height: 8),
                ...options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: option['is_correct'],
                          activeColor: FormateurTheme.success,
                          onChanged: (v) {
                            setDialogState(() {
                              // Multiple choice allowed? Let's say yes but usually single correct for basic
                              // For now allow toggle
                              options[index]['is_correct'] = v == true;
                            });
                          },
                        ),
                        Expanded(
                          child: TextFormField(
                            initialValue: option['content'],
                            onChanged: (v) => options[index]['content'] = v,
                            decoration: InputDecoration(
                              hintText: 'Option ${index + 1}',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        if (options.length > 2)
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setDialogState(() => options.removeAt(index)),
                          ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => setDialogState(() => options.add({'content': '', 'is_correct': false})),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une option'),
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
                if (questionCtrl.text.isEmpty) return;
                // Validate options
                if (options.any((o) => o['content'].toString().isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remplissez toutes les options')));
                  return;
                }
                
                final payload = {
                  'content': questionCtrl.text,
                  'points': int.tryParse(pointsCtrl.text) ?? 1,
                  'type': 'qcm',
                  'reponses': options,
                };

                Navigator.pop(context); // Close dialog

                final success = await _repository.addQuestion(widget.quizId, payload);
                if (mounted) {
                  if (success) {
                    _loadQuiz();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question ajoutée'), backgroundColor: FormateurTheme.success));
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur ajout'), backgroundColor: FormateurTheme.error));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: FormateurTheme.accentDark, foregroundColor: Colors.white),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteQuestion(int questionId) async {
    final success = await _repository.deleteQuestion(widget.quizId, questionId);
    if (success) {
      _loadQuiz();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question supprimée')));
      }
    }
  }

  Future<void> _publishQuiz() async {
    final success = await _repository.publishQuiz(widget.quizId);
    if (success) {
      _loadQuiz();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz publié !'), backgroundColor: FormateurTheme.success));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormateurTheme.background,
      appBar: AppBar(
        title: Text(_quiz?.titre ?? 'Chargement...'),
        backgroundColor: Colors.white,
        foregroundColor: FormateurTheme.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
             color: FormateurTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 18),
        actions: [
           if (_quiz != null && _quiz?.status != 'actif')
            TextButton.icon(
              onPressed: _publishQuiz,
              icon: const Icon(Icons.public, size: 16),
              label: const Text('Publier', style: TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: FormateurTheme.accentDark),
            ),
           const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FormateurTheme.accent))
          : _quiz == null
              ? const Center(child: Text('Erreur chargement quiz'))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Header Info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: FormateurTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _quiz!.status == 'actif' ? FormateurTheme.success.withOpacity(0.1) : FormateurTheme.orangeAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_quiz!.status, style: TextStyle(color: _quiz!.status == 'actif' ? FormateurTheme.success : FormateurTheme.orangeAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                              const SizedBox(width: 12),
                              Text('${_quiz!.questions.length} Questions', style: const TextStyle(color: FormateurTheme.textSecondary, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              Text('${_quiz!.duree} min', style: const TextStyle(color: FormateurTheme.textSecondary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          if (_quiz!.description != null) ...[
                            const SizedBox(height: 12),
                            Text(_quiz!.description!, style: const TextStyle(color: FormateurTheme.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Questions', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: FormateurTheme.textTertiary, letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    
                    if (_quiz!.questions.isEmpty)
                       Container(
                         padding: const EdgeInsets.all(32),
                         alignment: Alignment.center,
                         child: Column(
                           children: [
                             const Icon(Icons.quiz_outlined, size: 48, color: FormateurTheme.textTertiary),
                             const SizedBox(height: 16),
                             const Text('Aucune question ajoutée', style: TextStyle(color: FormateurTheme.textSecondary)),
                           ],
                         ),
                       )
                    else 
                      ..._quiz!.questions.map((q) => _buildQuestionCard(q)),
                      
                    const SizedBox(height: 80), // Fab space
                  ],
                ),
       floatingActionButton: FloatingActionButton.extended(
         onPressed: _addQuestion,
         backgroundColor: FormateurTheme.accentDark,
         icon: const Icon(Icons.add, color: Colors.white),
         label: const Text('Ajouter une question', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
       ),
    );
  }

  Widget _buildQuestionCard(Question q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FormateurTheme.border),
        boxShadow: FormateurTheme.cardShadow,
      ),
      child: ExpansionTile(
        title: Text(q.content, style: const TextStyle(fontWeight: FontWeight.bold, color: FormateurTheme.textPrimary)),
        subtitle: Text('${q.points} pt(s) • ${q.type}', style: const TextStyle(fontSize: 12, color: FormateurTheme.textSecondary)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: FormateurTheme.error),
          onPressed: () => _deleteQuestion(q.id),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: q.reponses.map((r) => Row(
                children: [
                   Icon(r.isCorrect ? Icons.check_circle : Icons.circle_outlined, size: 16, color: r.isCorrect ? FormateurTheme.success : FormateurTheme.textTertiary),
                   const SizedBox(width: 8),
                   Expanded(child: Text(r.content, style: TextStyle(color: r.isCorrect ? FormateurTheme.textPrimary : FormateurTheme.textSecondary, fontWeight: r.isCorrect ? FontWeight.bold : FontWeight.normal))),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
