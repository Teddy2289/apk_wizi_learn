import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';

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
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
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
          title: const Text('Créer un quiz'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Titre'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description (optionnel)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: niveau,
                  decoration: const InputDecoration(labelText: 'Niveau'),
                  items: const [
                    DropdownMenuItem(value: 'debutant', child: Text('Débutant')),
                    DropdownMenuItem(value: 'intermediaire', child: Text('Intermédiaire')),
                    DropdownMenuItem(value: 'avance', child: Text('Avancé')),
                  ],
                  onChanged: (v) => setDialogState(() => niveau = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(labelText: 'Durée (minutes)'),
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
              child: const Text('Annuler'),
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
                      const SnackBar(content: Text('Quiz créé'), backgroundColor: Colors.green),
                    );
                  }
                  _loadQuizzes();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF7931E)),
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
          const SnackBar(content: Text('Quiz supprimé'), backgroundColor: Colors.green),
        );
      }
      _loadQuizzes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Quiz'),
        backgroundColor: const Color(0xFFF7931E),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _quizzes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.quiz, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Aucun quiz créé', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _createQuiz,
                        icon: const Icon(Icons.add),
                        label: const Text('Créer le premier quiz'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF7931E)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = _quizzes[index];
                    final status = quiz['status'] ?? 'brouillon';
                    final statusColor = status == 'actif'
                        ? Colors.green
                        : status == 'archive'
                            ? Colors.grey
                            : Colors.orange;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(quiz['titre'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${quiz['nb_questions'] ?? 0} questions • ${quiz['niveau'] ?? ''} • ${quiz['duree'] ?? 0} min',
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'view', child: Text('Voir détails')),
                            const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                          ],
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteQuiz(quiz['id']);
                            }
                          },
                        ),
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createQuiz,
        backgroundColor: const Color(0xFFF7931E),
        child: const Icon(Icons.add),
      ),
    );
  }
}
