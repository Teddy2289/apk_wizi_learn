import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/repositories/quiz_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/stats_repository.dart';
import 'package:wizi_learn/features/auth/data/models/quiz_model.dart' as quiz_model;
import 'package:wizi_learn/features/auth/data/models/stats_model.dart' as stats_model;
import 'package:wizi_learn/features/auth/presentation/pages/quiz_session_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:confetti/confetti.dart';
import 'package:wizi_learn/features/auth/presentation/pages/achievement_page.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/animation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/avatar_selector_dialog.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/mission_card.dart';
import 'package:wizi_learn/features/auth/presentation/pages/avatar_shop_page.dart';

class QuizAdventurePage extends StatefulWidget {
  const QuizAdventurePage({Key? key}) : super(key: key);

  @override
  State<QuizAdventurePage> createState() => _QuizAdventurePageState();
}

class _QuizAdventurePageState extends State<QuizAdventurePage> with SingleTickerProviderStateMixin {
  late final QuizRepository _quizRepository;
  late final StatsRepository _statsRepository;
  int? _connectedStagiaireId;
  List<quiz_model.Quiz> _quizzes = [];
  List<String> _playedQuizIds = [];
  bool _isLoading = true;
  int _userPoints = 0;
  ConfettiController? _confettiController;
  int _lastCompletedCount = 0;
  List<stats_model.QuizHistory> _quizHistory = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _avatarIndex = 0;
  late AnimationController _avatarAnimController;
  late Animation<double> _avatarAnim;
  late AnimationController _avatarBounceController;
  late Animation<double> _avatarBounceAnim;
  String _avatarPath = 'assets/images/avatar.png';
  final List<String> _avatarChoices = [
    'assets/images/avatars/avatar1.png',
    'assets/images/avatars/avatar2.png',
    'assets/images/avatars/avatar3.png',
    'assets/images/avatars/avatar4.png',
    'assets/images/avatars/avatar5.png',
    'assets/images/avatar.png',
  ];
  int _loginStreak = 1; // Valeur simulée pour la démo, à remplacer par la vraie valeur API si dispo

  @override
  void initState() {
    super.initState();
    final dio = Dio();
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(dio: dio, storage: storage);
    _quizRepository = QuizRepository(apiClient: apiClient);
    _statsRepository = StatsRepository(apiClient: apiClient);
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _avatarAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _avatarAnim = CurvedAnimation(parent: _avatarAnimController, curve: Curves.easeInOut);
    _avatarBounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _avatarBounceAnim = CurvedAnimation(parent: _avatarBounceController, curve: Curves.elasticOut);
    _loadLoginStreak();
    _loadAvatarChoice();
    _loadData();
  }

  @override
  void dispose() {
    _confettiController?.dispose();
    _audioPlayer.dispose();
    _avatarBounceController.dispose();
    _avatarAnimController.dispose();
    super.dispose();
  }

  Future<void> _playSound(String asset) async {
    try {
      await _audioPlayer.play(AssetSource(asset));
    } catch (e) {
      // ignore errors silently
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Récupérer l'utilisateur connecté
      final user = await storage.read(key: 'user');
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      // On suppose que l'id stagiaire est stocké dans le user JSON
      final id = RegExp(r'"id":\s*(\d+)').firstMatch(user)?.group(1);
      _connectedStagiaireId = id != null ? int.tryParse(id) : null;
      if (_connectedStagiaireId == null) {
        setState(() => _isLoading = false);
        return;
      }
      // Récupérer les quiz
      final quizzes = await _quizRepository.getQuizzesForStagiaire(stagiaireId: _connectedStagiaireId);
      // Récupérer l'historique
      final history = await _statsRepository.getQuizHistory(page: 1, limit: 100);
      // Récupérer les points
      final rankings = await _statsRepository.getGlobalRanking();
      final userRanking = rankings.firstWhere(
        (r) => r.stagiaire.id == _connectedStagiaireId.toString(),
        orElse: () => GlobalRanking.empty(),
      );
      setState(() {
        _quizzes = quizzes;
        _playedQuizIds = history.map((h) => h.quiz.id).toList();
        _quizHistory = history;
        _userPoints = userRanking.totalPoints;
        _isLoading = false;
      });
      // Animation confettis si progression
      final completed = quizzes.where((q) => _playedQuizIds.contains(q.id.toString())).length;
      if (completed > _lastCompletedCount && _lastCompletedCount != 0) {
        _confettiController?.play();
        await _playSound('audio/success.mp3');
      }
      _lastCompletedCount = completed;

      // Calcul de la position de l'avatar
      int lastPlayed = 0;
      for (int i = 0; i < quizzes.length; i++) {
        if (_playedQuizIds.contains(quizzes[i].id.toString())) {
          lastPlayed = i;
        } else {
          break;
        }
      }
      int newAvatarIndex = lastPlayed;
      if (lastPlayed < quizzes.length - 1 && !_playedQuizIds.contains(quizzes[lastPlayed + 1].id.toString())) {
        newAvatarIndex = lastPlayed + 1;
      }
      if (mounted && newAvatarIndex != _avatarIndex) {
        _avatarAnimController.forward(from: 0);
        _avatarBounceController.forward(from: 0);
      }
      setState(() {
        _avatarIndex = newAvatarIndex;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLoginStreak() async {
    // À remplacer par un appel API réel si disponible
    // Pour la démo, on stocke la date du dernier lancement dans SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString('last_login_date');
    final today = DateTime.now();
    if (lastDateStr != null) {
      final lastDate = DateTime.tryParse(lastDateStr);
      if (lastDate != null) {
        if (lastDate.year == today.year && lastDate.month == today.month && lastDate.day == today.day) {
          // déjà compté aujourd'hui
        } else if (lastDate.add(const Duration(days: 1)).year == today.year && lastDate.add(const Duration(days: 1)).month == today.month && lastDate.add(const Duration(days: 1)).day == today.day) {
          // connexion consécutive
          _loginStreak = (prefs.getInt('login_streak') ?? 1) + 1;
        } else {
          // streak cassé
          _loginStreak = 1;
        }
      }
    }
    await prefs.setString('last_login_date', today.toIso8601String());
    await prefs.setInt('login_streak', _loginStreak);
    setState(() {});
  }

  Future<void> _loadAvatarChoice() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _avatarPath = prefs.getString('selected_avatar') ?? 'assets/images/avatar.png';
    });
  }

  Future<void> _selectAvatar() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AvatarSelectorDialog(
        avatarPaths: _avatarChoices,
        selectedAvatar: _avatarPath,
      ),
    );
    if (selected != null && selected != _avatarPath) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_avatar', selected);
      setState(() {
        _avatarPath = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aventure Quiz'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag),
            tooltip: 'Boutique d\'avatars',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AvatarShopPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Changer d\'avatar',
            onPressed: _selectAvatar,
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Mes Badges',
            onPressed: () {
              _playSound('audio/click.mp3');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AchievementPage()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
              : _quizzes.isEmpty
                  ? Center(child: Text('Aucun quiz disponible'))
                  : Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildProgressBar(theme),
                        // Section Missions du jour
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text('Missions du jour', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ),
                              MissionCard(
                                title: 'Série de connexion',
                                description: 'Connecte-toi plusieurs jours d\'affilée pour gagner un badge.',
                                progress: _loginStreak,
                                goal: 5,
                                reward: 'Badge',
                              ),
                              MissionCard(
                                title: 'Réussir 2 quiz',
                                description: 'Complète 2 quiz aujourd\'hui pour gagner un badge.',
                                progress: _quizHistory.length >= 2 ? 2 : _quizHistory.length,
                                goal: 2,
                                reward: 'Badge',
                              ),
                              MissionCard(
                                title: 'Obtenir 5 étoiles',
                                description: 'Cumule 5 étoiles sur tes quiz.',
                                progress: _quizHistory.fold(0, (sum, h) {
                                  final percent = h.totalQuestions > 0 ? (h.correctAnswers / h.totalQuestions) * 100 : 0;
                                  if (percent >= 100) return sum + 3;
                                  if (percent >= 70) return sum + 2;
                                  if (percent >= 40) return sum + 1;
                                  return sum;
                                }),
                                goal: 5,
                                reward: 'Badge',
                              ),
                              MissionCard(
                                title: 'Jouer un quiz difficile',
                                description: 'Termine un quiz de niveau avancé.',
                                progress: _quizHistory.any((h) => h.quiz.level.toLowerCase().contains('avanc')) ? 1 : 0,
                                goal: 1,
                                reward: 'Points',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final itemWidth = 120.0;
                              return Stack(
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: List.generate(_quizzes.length, (index) {
                                        final quiz = _quizzes[index];
                                        final isPlayed = _playedQuizIds.contains(quiz.id.toString());
                                        final isUnlocked = _isQuizUnlocked(index);
                                        final history = _quizHistory.firstWhere(
                                          (h) => h.quiz.id == quiz.id.toString(),
                                          orElse: () => null,
                                        );
                                        int stars = 0;
                                        if (history != null && history.totalQuestions > 0) {
                                          final percent = (history.correctAnswers / history.totalQuestions) * 100;
                                          if (percent >= 100) {
                                            stars = 3;
                                          } else if (percent >= 70) {
                                            stars = 2;
                                          } else if (percent >= 40) {
                                            stars = 1;
                                          }
                                        }
                                        return SizedBox(
                                          width: itemWidth,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                            child: GestureDetector(
                                              onTap: isUnlocked
                                                  ? () async {
                                                      await _playSound('audio/click.mp3');
                                                      final questions = quiz.questions;
                                                      if (questions.isEmpty) return;
                                                      final result = await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) => QuizSessionPage(quiz: quiz, questions: questions),
                                                        ),
                                                      );
                                                      if (result == 'fail' || (history != null && stars == 0)) {
                                                        await _playSound('audio/fail.mp3');
                                                      }
                                                      _loadData();
                                                    }
                                                  : null,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  _AnimatedQuizStep(
                                                    icon: isPlayed
                                                        ? Icons.emoji_events
                                                        : isUnlocked
                                                            ? Icons.star
                                                            : Icons.lock,
                                                    color: isPlayed
                                                        ? Colors.amber
                                                        : isUnlocked
                                                            ? theme.colorScheme.primary
                                                            : Colors.grey,
                                                    label: quiz.titre,
                                                    isCompleted: isPlayed,
                                                    isUnlocked: isUnlocked,
                                                  ),
                                                  if (isPlayed)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 4.0),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: List.generate(3, (i) => Icon(
                                                          Icons.star,
                                                          size: 18,
                                                          color: i < stars ? Colors.amber : Colors.grey[300],
                                                        )),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                  // Avatar animé
                                  AnimatedBuilder(
                                    animation: Listenable.merge([_avatarAnim, _avatarBounceAnim]),
                                    builder: (context, child) {
                                      final itemWidth = 120.0;
                                      final dx = (_avatarIndex * itemWidth + 16.0 * (_avatarIndex * 2 + 1)) * _avatarAnim.value;
                                      final scale = 1.0 + 0.15 * _avatarBounceAnim.value;
                                      return Positioned(
                                        left: dx,
                                        bottom: 0,
                                        child: SizedBox(
                                          width: itemWidth,
                                          child: Center(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.yellow.withOpacity(0.6 * _avatarBounceAnim.value),
                                                    blurRadius: 24 * _avatarBounceAnim.value,
                                                    spreadRadius: 2 * _avatarBounceAnim.value,
                                                  ),
                                                ],
                                              ),
                                              child: Transform.scale(
                                                scale: scale,
                                                child: Image.asset(
                                                  _avatarPath,
                                                  width: 48,
                                                  height: 48,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
          // Confetti animation
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController!,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
              emissionFrequency: 0.08,
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 8,
            ),
          ),
        ],
      ),
    );
  }

  bool _isQuizUnlocked(int index) {
    // Premier quiz toujours débloqué, les suivants si le précédent est joué
    if (index == 0) return true;
    final prevQuiz = _quizzes[index - 1];
    return _playedQuizIds.contains(prevQuiz.id.toString());
  }

  Widget _buildProgressBar(ThemeData theme) {
    final completed = _quizzes.where((q) => _playedQuizIds.contains(q.id.toString())).length;
    final total = _quizzes.length;
    final percent = total == 0 ? 0.0 : completed / total;
    return Column(
      children: [
        Text('Progression : $completed / $total quiz complétés', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent,
          minHeight: 8,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }
}

// Widget animé pour rebond sur l'icône du quiz complété
class _AnimatedQuizStep extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool isCompleted;
  final bool isUnlocked;
  const _AnimatedQuizStep({
    required this.icon,
    required this.color,
    required this.label,
    required this.isCompleted,
    required this.isUnlocked,
    Key? key,
  }) : super(key: key);

  @override
  State<_AnimatedQuizStep> createState() => _AnimatedQuizStepState();
}

class _AnimatedQuizStepState extends State<_AnimatedQuizStep> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.9,
      upperBound: 1.15,
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    if (widget.isCompleted) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedQuizStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _controller.forward(from: 0.9);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _scaleAnim,
          child: Icon(widget.icon, size: 48, color: widget.color),
        ),
        const SizedBox(height: 8),
        Text(
          widget.label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: widget.isUnlocked ? Theme.of(context).colorScheme.onSurface : Colors.grey,
          ),
        ),
      ],
    );
  }
} 