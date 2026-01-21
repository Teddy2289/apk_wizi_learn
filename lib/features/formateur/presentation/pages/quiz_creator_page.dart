import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';

class QuizCreatorPage extends StatefulWidget {
  const QuizCreatorPage({super.key});

  @override
  State<QuizCreatorPage> createState() => _QuizCreatorPageState();
}

class _QuizCreatorPageState extends State<QuizCreatorPage> {
  late final ApiClient _apiClient;
  List<Map<String, dynamic>> _quizzes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _loading = true);
    try {
      final response = await _apiClient.get('/formateur/quizzes');
      setState(() {
        _quizzes = List<Map<String, dynamic>>.from(response.data['quizzes'] ?? []);
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
                  padding: const EdgeInsets.all(24),
                  itemCount: _quizzes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final quiz = _quizzes[index];
                    final status = quiz['status'] ?? 'brouillon';
                    final statusColor = status == 'actif'
                        ? FormateurTheme.success
                        : status == 'archive'
                            ? FormateurTheme.textTertiary
                            : FormateurTheme.orangeAccent;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: FormateurTheme.border),
                        boxShadow: FormateurTheme.cardShadow,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(20),
                        title: Text(
                          quiz['titre'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: FormateurTheme.textPrimary),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.help_outline, size: 14, color: FormateurTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text('${quiz['nb_questions'] ?? 0} questions', style: const TextStyle(fontSize: 12, color: FormateurTheme.textSecondary)),
                              const SizedBox(width: 16),
                              Icon(Icons.timer_outlined, size: 14, color: FormateurTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text('${quiz['duree'] ?? 0} min', style: const TextStyle(fontSize: 12, color: FormateurTheme.textSecondary)),
                            ],
                          ),
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
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
                            }
                          },
                        ),
                      ),
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
