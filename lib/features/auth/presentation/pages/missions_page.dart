import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/mission_model.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/mission_card.dart';
import 'package:wizi_learn/features/auth/data/models/stats_model.dart' as stats_model;

class MissionsPage extends StatelessWidget {
  final int loginStreak;
  final List<stats_model.QuizHistory> quizHistory;
  const MissionsPage({super.key, required this.loginStreak, required this.quizHistory});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions du jour'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MissionCard(
            mission: Mission(
              id: 1,
              title: 'Série de connexion',
              description: 'Connecte-toi plusieurs jours d\'affilée pour gagner un badge.',
              type: 'daily',
              goal: 5,
              reward: 'Badge',
              progress: loginStreak,
              completed: loginStreak >= 5,
              completedAt: null,
            ),
          ),
          MissionCard(
            mission: Mission(
              id: 2,
              title: 'Réussir 2 quiz',
              description: 'Complète 2 quiz aujourd\'hui pour gagner un badge.',
              type: 'daily',
              goal: 2,
              reward: 'Badge',
              progress: quizHistory.length >= 2 ? 2 : quizHistory.length,
              completed: quizHistory.length >= 2,
              completedAt: null,
            ),
          ),
          MissionCard(
            mission: Mission(
              id: 3,
              title: 'Obtenir 5 étoiles',
              description: 'Cumule 5 étoiles sur tes quiz.',
              type: 'daily',
              goal: 5,
              reward: 'Badge',
              progress: quizHistory.fold(0, (sum, h) {
                final percent = h.totalQuestions > 0 ? (h.correctAnswers / h.totalQuestions) * 100 : 0;
                if (percent >= 100) return sum + 3;
                if (percent >= 70) return sum + 2;
                if (percent >= 40) return sum + 1;
                return sum;
              }),
              completed: quizHistory.fold(0, (sum, h) {
                final percent = h.totalQuestions > 0 ? (h.correctAnswers / h.totalQuestions) * 100 : 0;
                if (percent >= 100) return sum + 3;
                if (percent >= 70) return sum + 2;
                if (percent >= 40) return sum + 1;
                return sum;
              }) >= 5,
              completedAt: null,
            ),
          ),
          MissionCard(
            mission: Mission(
              id: 4,
              title: 'Jouer un quiz difficile',
              description: 'Termine un quiz de niveau avancé.',
              type: 'daily',
              goal: 1,
              reward: 'Points',
              progress: quizHistory.any((h) => h.quiz.niveau.toLowerCase().contains('avanc')) ? 1 : 0,
              completed: quizHistory.any((h) => h.quiz.niveau.toLowerCase().contains('avanc')),
              completedAt: null,
            ),
          ),
        ],
      ),
    );
  }
}import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:wizi_learn/features/auth/data/models/mission_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/mission_repository.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/mission_card.dart';

class MissionsPage extends StatefulWidget {
  const MissionsPage({Key? key}) : super(key: key);

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  late final MissionRepository _repo;
  List<Mission> _missions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repo = MissionRepository(dio: Dio());
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    setState(() => _isLoading = true);
    final missions = await _repo.getMissions();
    setState(() {
      _missions = missions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _missions.length,
              itemBuilder: (context, index) {
                final mission = _missions[index];
                return MissionCard(mission: mission);
              },
            ),
    );
  }
} 