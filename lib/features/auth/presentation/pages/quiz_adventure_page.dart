import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/repositories/quiz_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/stats_repository.dart';
import 'package:wizi_learn/features/auth/data/models/quiz_model.dart'
    as quiz_model;
import 'package:wizi_learn/features/auth/data/models/stats_model.dart'
    as stats_model;
import 'package:wizi_learn/features/auth/presentation/pages/quiz_session_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:confetti/confetti.dart';
import 'package:wizi_learn/features/auth/presentation/pages/achievement_page.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/avatar_selector_dialog.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/mission_card.dart';
import 'package:wizi_learn/features/auth/data/models/mission_model.dart';
import 'package:wizi_learn/features/auth/presentation/pages/avatar_shop_page.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:wizi_learn/features/auth/data/repositories/auth_repository.dart';
import 'package:wizi_learn/features/auth/data/datasources/auth_remote_data_source.dart';

class QuizAdventurePage extends StatefulWidget {
  const QuizAdventurePage({super.key});

  @override
  State<QuizAdventurePage> createState() => _QuizAdventurePageState();
}

class _QuizAdventurePageState extends State<QuizAdventurePage> with TickerProviderStateMixin {
  late final QuizRepository _quizRepository;
  late final StatsRepository _statsRepository;
  late final AuthRepository _authRepository;
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
  int _loginStreak =
      1; // Valeur simulée pour la démo, à remplacer par la vraie valeur API si dispo

  // GlobalKeys pour le tutoriel interactif
  final GlobalKey _keyShop = GlobalKey();
  final GlobalKey _keyAvatar = GlobalKey();
  final GlobalKey _keyBadges = GlobalKey();
  final GlobalKey _keyProgress = GlobalKey();
  final GlobalKey _keyMission = GlobalKey();
  final GlobalKey _keyQuiz = GlobalKey();
  final GlobalKey _keyAvatarAnim = GlobalKey();
  // TutorialCoachMark? _tutorialCoachMark; // Unused field removed
  // bool _tutorialShown = false; // Unused field removed

  @override
  void initState() {
    super.initState();
    _initializeRepositories();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _avatarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _avatarAnim = CurvedAnimation(
      parent: _avatarAnimController,
      curve: Curves.easeInOut,
    );
    _avatarBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _avatarBounceAnim = CurvedAnimation(
      parent: _avatarBounceController,
      curve: Curves.elasticOut,
    );
    _loadLoginStreak();
    _loadAvatarChoice();
    _loadInitialData();
    _checkAndShowTutorial();
  }

  void _initializeRepositories() {
    final dio = Dio();
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(dio: dio, storage: storage);
    _quizRepository = QuizRepository(apiClient: apiClient);
    _statsRepository = StatsRepository(apiClient: apiClient);
    _authRepository = AuthRepository(
      remoteDataSource: AuthRemoteDataSourceImpl(
        apiClient: apiClient,
        storage: storage,
      ),
      storage: storage,
    );
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authRepository.getMe();
      _connectedStagiaireId = user.stagiaire?.id;
      if (_connectedStagiaireId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final quizzes = await _quizRepository.getQuizzesForStagiaire(
        stagiaireId: _connectedStagiaireId,
      );
      print('--- QUIZZES RECUS ---');
      for (var q in quizzes) {
        print('id= [32m${q.id} [0m, titre=${q.titre}, niveau=${q.niveau}, status=${q.status}');
      }
      print('---------------------');
      final history = await _statsRepository.getQuizHistory(
        page: 1,
        limit: 100,
      );
      final rankings = await _statsRepository.getGlobalRanking();
      final userRanking = rankings.firstWhere(
        (r) => r.stagiaire.id == _connectedStagiaireId.toString(),
        orElse: () => stats_model.GlobalRanking.empty(),
      );
      _userPoints = userRanking.totalPoints;
      final filteredQuizzes = _filterQuizzesByPoints(quizzes, _userPoints);
      setState(() {
        _quizzes = filteredQuizzes;
        _playedQuizIds = history.map((h) => h.quiz.id.toString()).toList();
        _quizHistory = history;
        _isLoading = false;
      });
      // Animation confettis si progression
      final completed =
          filteredQuizzes.where((q) => _playedQuizIds.contains(q.id.toString())).length;
      if (completed > _lastCompletedCount && _lastCompletedCount != 0) {
        _confettiController?.play();
        await _playSound('audio/success.mp3');
      }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boardRows = 2;
    final boardCols = (_quizzes.length / boardRows).ceil();
    final tileSize = 80.0;
    final avatarSize = 56.0;
    final avatarPos = _avatarIndex;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
              : _quizzes.isEmpty
                  ? Center(child: Text('Aucun quiz disponible'))
                  : Column(
                      children: [
                        const SizedBox(height: 16),
                        Container(key: _keyProgress, child: _buildProgressBar(theme)),
                        const SizedBox(height: 24),
                        // Mario Party-like board
                        Center(
                          child: SizedBox(
                            width: boardCols * tileSize + 32,
                            height: boardRows * tileSize + 32,
                            child: Stack(
                              children: [
                                // Board grid
                                for (int row = 0; row < boardRows; row++)
                                  for (int col = 0; col < boardCols; col++)
                                    if (row * boardCols + col < _quizzes.length)
                                      Positioned(
                                        left: col * tileSize + 16,
                                        top: row * tileSize + 16,
                                        child: _buildBoardTile(
                                          context,
                                          _quizzes[row * boardCols + col],
                                          row * boardCols + col,
                                          tileSize,
                                        ),
                                      ),
                                // Path arrows
                                for (int i = 0; i < _quizzes.length - 1; i++)
                                  _buildArrow(
                                    from: i,
                                    to: i + 1,
                                    boardCols: boardCols,
                                    tileSize: tileSize,
                                  ),
                                // Animated avatar
                                AnimatedBuilder(
                                  animation: Listenable.merge([
                                    _avatarAnim,
                                    _avatarBounceAnim,
                                  ]),
                                  builder: (context, child) {
                                    final row = (avatarPos / boardCols).floor();
                                    final col = avatarPos % boardCols;
                                    final dx = col * tileSize + 16;
                                    final dy = row * tileSize + 16;
                                    final scale = 1.0 + 0.15 * _avatarBounceAnim.value;
                                    return Positioned(
                                      left: dx + tileSize / 2 - avatarSize / 2,
                                      top: dy + tileSize / 2 - avatarSize / 2,
                                      child: Transform.scale(
                                        scale: scale,
                                        child: Image.asset(
                                          _avatarPath,
                                          width: avatarSize,
                                          height: avatarSize,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Missions section (unchanged)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MissionCard(),
                              MissionCard(),
                              MissionCard(),
                            ],
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

  // Board tile widget
  Widget _buildBoardTile(BuildContext context, quiz_model.Quiz quiz, int index, double size) {
    final isPlayed = _playedQuizIds.contains(quiz.id.toString());
    final isUnlocked = _isQuizUnlocked(index);
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: isUnlocked && quiz.questions.isNotEmpty
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
              _loadInitialData();
            }
          : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPlayed
              ? Colors.greenAccent.withOpacity(0.7)
              : isUnlocked
                  ? Colors.blueAccent.withOpacity(0.7)
                  : Colors.grey.withOpacity(0.5),
          border: Border.all(
            color: isUnlocked ? theme.colorScheme.primary : Colors.grey,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              isPlayed
                  ? Icons.check_circle
                  : isUnlocked
                      ? Icons.casino
                      : Icons.lock,
              color: isPlayed
                  ? Colors.green
                  : isUnlocked
                      ? Colors.white
                      : Colors.grey[700],
              size: 32,
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                quiz.titre,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? theme.colorScheme.onPrimary : Colors.grey[800],
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Arrow widget between tiles
  Widget _buildArrow({required int from, required int to, required int boardCols, required double tileSize}) {
    final fromRow = (from / boardCols).floor();
    final fromCol = from % boardCols;
    final toRow = (to / boardCols).floor();
    final toCol = to % boardCols;
    final arrowColor = Colors.orangeAccent;
    final arrowSize = 32.0;
    double left, top, angle;
    if (fromRow == toRow) {
      // Horizontal arrow
      left = fromCol * tileSize + tileSize + 16 - arrowSize / 2;
      top = fromRow * tileSize + tileSize / 2 + 16 - arrowSize / 2;
      angle = 0;
    } else {
      // Vertical arrow
      left = fromCol * tileSize + tileSize / 2 + 16 - arrowSize / 2;
      top = fromRow * tileSize + tileSize + 16 - arrowSize / 2;
      angle = 1.5708; // 90 deg
    }
    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: angle,
        child: Icon(
          Icons.arrow_forward,
          color: arrowColor,
          size: arrowSize,
        ),
      ),
    );
  }
    final lastDateStr = prefs.getString('last_login_date');
    final today = DateTime.now();
    if (lastDateStr != null) {
      final lastDate = DateTime.tryParse(lastDateStr);
      if (lastDate != null) {
        if (lastDate.year == today.year &&
            lastDate.month == today.month &&
            lastDate.day == today.day) {
          // déjà compté aujourd'hui
        } else if (lastDate.add(const Duration(days: 1)).year == today.year &&
            lastDate.add(const Duration(days: 1)).month == today.month &&
            lastDate.add(const Duration(days: 1)).day == today.day) {
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
      _avatarPath =
          prefs.getString('selected_avatar') ?? 'assets/images/avatar.png';
    });
  }

  Future<void> _selectAvatar() async {
    final selected = await showDialog<String>(
      context: context,
      builder:
          (context) => AvatarSelectorDialog(
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

  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('adventure_tutorial_seen') ?? false;
    if (!seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorial());
      await prefs.setBool('adventure_tutorial_seen', true);
    }
  }

  void _showTutorial() {
    TutorialCoachMark(
      targets: _buildTargets(),
      colorShadow: Colors.black,
      textSkip: 'Passer',
      paddingFocus: 8,
      opacityShadow: 0.8,
      onFinish: () {},
      onSkip: () {
        return true;
      },
    ).show(context: context);
  }

  List<TargetFocus> _buildTargets() {
    return [
      TargetFocus(
        identify: 'shop',
        keyTarget: _keyShop,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Découvre la boutique pour personnaliser ton avatar !',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'avatar',
        keyTarget: _keyAvatar,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Change ton avatar à tout moment.',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'badges',
        keyTarget: _keyBadges,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Ici, retrouve tous tes badges débloqués !',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'progress',
        keyTarget: _keyProgress,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Suis ta progression dans l’aventure quiz.',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'mission',
        keyTarget: _keyMission,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Accomplis des missions pour gagner des récompenses !',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'quiz',
        keyTarget: _keyQuiz,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              'Clique sur un quiz débloqué pour commencer à jouer.',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'avatarAnim',
        keyTarget: _keyAvatarAnim,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              'Ton avatar progresse avec toi dans l’aventure !',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    ];
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
            key: _keyShop,
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
            key: _keyAvatar,
            icon: const Icon(Icons.person),
            tooltip: 'Changer d\'avatar',
            onPressed: _selectAvatar,
          ),
          IconButton(
            key: _keyBadges,
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
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Voir le tutoriel',
            onPressed: _showTutorial,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
              : _quizzes.isEmpty
              ? Center(child: Text('Aucun quiz disponible'))
              : Column(
                children: [
                  const SizedBox(height: 16),
                  Container(key: _keyProgress, child: _buildProgressBar(theme)),
                  // Bouton pour accéder à la page Missions
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: ElevatedButton.icon(
                        key: _keyMission,
                        icon: const Icon(Icons.flag),
                        label: const Text('Voir les missions'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MissionsPage(
                                loginStreak: _loginStreak,
                                quizHistory: _quizHistory,
                              ),
                            ),
                          );
                        },
                      ),
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
                                children: List.generate(_quizzes.length, (
                                  index,
                                ) {
                                  final quiz = _quizzes[index];
                                  final isPlayed = _playedQuizIds.contains(
                                    quiz.id.toString(),
                                  );
                                  final isUnlocked = _isQuizUnlocked(index);
                                  final history =
                                      _quizHistory.isNotEmpty
                                          ? _quizHistory.firstWhere(
                                            (h) =>
                                                h.quiz.id == quiz.id.toString(),
                                            orElse: () => _quizHistory.first,
                                          )
                                          : stats_model.QuizHistory(
                                            id: '',
                                            quiz: quiz,
                                            score: 0,
                                            completedAt: '',
                                            timeSpent: 0,
                                            totalQuestions: 0,
                                            correctAnswers: 0,
                                          );
                                  int stars = 0;
                                  if (history != null &&
                                      history.totalQuestions > 0) {
                                    final percent =
                                        (history.correctAnswers /
                                            history.totalQuestions) *
                                        100;
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: GestureDetector(
                                        key: index == 0 ? _keyQuiz : null,
                                        onTap:
                                            isUnlocked && quiz.questions.isNotEmpty
                                                ? () async {
                                                  await _playSound(
                                                    'audio/click.mp3',
                                                  );
                                                  final questions =
                                                      quiz.questions;
                                                  if (questions.isEmpty) return;
                                                  final result =
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (
                                                                _,
                                                              ) => QuizSessionPage(
                                                                quiz: quiz,
                                                                questions:
                                                                    questions,
                                                              ),
                                                        ),
                                                      );
                                                  if (result == 'fail' ||
                                                      (history != null &&
                                                          stars == 0)) {
                                                    await _playSound(
                                                      'audio/fail.mp3',
                                                    );
                                                  }
                                                  _loadInitialData();
                                                }
                                                : null,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            _AnimatedQuizStep(
                                              icon:
                                                  isPlayed
                                                      ? Icons.emoji_events
                                                      : isUnlocked
                                                      ? Icons.star
                                                      : Icons.lock,
                                              color:
                                                  isPlayed
                                                      ? Colors.amber
                                                      : isUnlocked
                                                      ? theme
                                                          .colorScheme
                                                          .primary
                                                      : Colors.grey,
                                              label: quiz.titre,
                                              isCompleted: isPlayed,
                                              isUnlocked: isUnlocked,
                                            ),
                                            if (quiz.questions.isEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4.0),
                                                child: Text(
                                                  'Aucune question disponible',
                                                  style: TextStyle(color: Colors.red, fontSize: 12),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            if (isPlayed)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4.0,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: List.generate(
                                                    3,
                                                    (i) => Icon(
                                                      Icons.star,
                                                      size: 18,
                                                      color:
                                                          i < stars
                                                              ? Colors.amber
                                                              : Colors
                                                                  .grey[300],
                                                    ),
                                                  ),
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
                              animation: Listenable.merge([
                                _avatarAnim,
                                _avatarBounceAnim,
                              ]),
                              builder: (context, child) {
                                final itemWidth = 120.0;
                                final dx =
                                    (_avatarIndex * itemWidth +
                                        16.0 * (_avatarIndex * 2 + 1)) *
                                    _avatarAnim.value;
                                final scale =
                                    1.0 + 0.15 * _avatarBounceAnim.value;
                                return Positioned(
                                  left: dx,
                                  bottom: 0,
                                  child: SizedBox(
                                    width: itemWidth,
                                    child: Center(
                                      child: Container(
                                        key: _keyAvatarAnim,
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.yellow.withOpacity(
                                                0.6 * _avatarBounceAnim.value,
                                              ),
                                              blurRadius:
                                                  24 * _avatarBounceAnim.value,
                                              spreadRadius:
                                                  2 * _avatarBounceAnim.value,
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
    final completed =
        _quizzes.where((q) => _playedQuizIds.contains(q.id.toString())).length;
    final total = _quizzes.length;
    final percent = total == 0 ? 0.0 : completed / total;
    return Column(
      children: [
        Text(
          'Progression : $completed / $total quiz complétés',
          style: theme.textTheme.bodyMedium,
        ),
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
