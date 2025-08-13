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
import 'package:wizi_learn/features/auth/presentation/pages/quiz_page.dart';

class QuizAdventurePage extends StatefulWidget {
  final bool quizAdventureEnabled;
  const QuizAdventurePage({super.key, this.quizAdventureEnabled = true});

  @override
  State<QuizAdventurePage> createState() => _QuizAdventurePageState();
}

class _QuizAdventurePageState extends State<QuizAdventurePage>
    with TickerProviderStateMixin {
  late final QuizRepository _quizRepository;
  late final StatsRepository _statsRepository;
  late final AuthRepository _authRepository;
  int? _connectedStagiaireId;
  List<quiz_model.Quiz> _allQuizzes = [];
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
  bool _showMissions = false;
  String? _selectedFormationTitle;
  List<String> _availableFormationTitles = [];
  bool _showAllForFormation = false;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

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
    _scrollController.addListener(() {
      final show = _scrollController.offset >= 400;
      if (show != _showBackToTopButton && mounted) {
        setState(() => _showBackToTopButton = show);
      }
    });
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
        print(
          'id= [32m${q.id} [0m, titre=${q.titre}, niveau=${q.niveau}, status=${q.status}',
        );
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
        _allQuizzes = quizzes;
        _quizzes = filteredQuizzes;
        _playedQuizIds = history.map((h) => h.quiz.id.toString()).toList();
        _quizHistory = history;
        _isLoading = false;
        // Build available formation titles for filter
        _availableFormationTitles =
            _allQuizzes
                .map((q) => q.formation.titre)
                .where((t) => t.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        // Select first formation by default if none selected yet
        if (_selectedFormationTitle == null &&
            _availableFormationTitles.isNotEmpty) {
          _selectedFormationTitle = _availableFormationTitles.first;
          _showAllForFormation = false;
        }
      });
      // Animation confettis si progression
      final completed =
          filteredQuizzes
              .where((q) => _playedQuizIds.contains(q.id.toString()))
              .length;
      if (completed > _lastCompletedCount && _lastCompletedCount != 0) {
        _confettiController?.play();
        await _playSound('audio/success.mp3');
      }
      _lastCompletedCount = completed;
      // Calcul de la position de l'avatar
      int lastPlayed = 0;
      for (int i = 0; i < filteredQuizzes.length; i++) {
        if (_playedQuizIds.contains(filteredQuizzes[i].id.toString())) {
          lastPlayed = i;
        } else {
          break;
        }
      }
      int newAvatarIndex = lastPlayed;
      if (lastPlayed < filteredQuizzes.length - 1 &&
          !_playedQuizIds.contains(
            filteredQuizzes[lastPlayed + 1].id.toString(),
          )) {
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

  @override
  void dispose() {
    _confettiController?.dispose();
    _audioPlayer.dispose();
    _avatarBounceController.dispose();
    _avatarAnimController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _playSound(String asset) async {
    try {
      await _audioPlayer.play(AssetSource(asset));
    } catch (e) {
      // ignore errors silently
    }
  }

  // Ajout de la méthode de filtrage des quiz par points utilisateur
  List<quiz_model.Quiz> _filterQuizzesByPoints(
    List<quiz_model.Quiz> allQuizzes,
    int userPoints,
  ) {
    if (allQuizzes.isEmpty) return [];

    String normalizeLevel(String? level) {
      if (level == null) return 'débutant';
      final lvl = level.toLowerCase().trim();
      if (lvl.contains('inter') || lvl.contains('moyen'))
        return 'intermédiaire';
      if (lvl.contains('avancé') || lvl.contains('expert')) return 'avancé';
      return 'débutant';
    }

    final debutant =
        allQuizzes
            .where((q) => normalizeLevel(q.niveau) == 'débutant')
            .toList();
    final intermediaire =
        allQuizzes
            .where((q) => normalizeLevel(q.niveau) == 'intermédiaire')
            .toList();
    final avance =
        allQuizzes.where((q) => normalizeLevel(q.niveau) == 'avancé').toList();

    List<quiz_model.Quiz> filtered = [];
    if (userPoints < 10)
      filtered = debutant.take(2).toList();
    // else if (userPoints < 20)
    //   filtered = debutant.take(4).toList();
    // else if (userPoints < 40)
    //   filtered = [...debutant, ...intermediaire.take(2)];
    // else if (userPoints < 60)
    //   filtered = [...debutant, ...intermediaire];
    // else if (userPoints < 80)
    //   filtered = [...debutant, ...intermediaire, ...avance.take(2)];
    // else if (userPoints < 100)
    //   filtered = [...debutant, ...intermediaire, ...avance.take(4)];
    else
      filtered = [...debutant, ...intermediaire, ...avance];

    // Fallback: si aucun quiz filtré mais la liste d'origine n'est pas vide, retourne au moins le premier quiz
    if (filtered.isEmpty && allQuizzes.isNotEmpty) {
      filtered = [allQuizzes.first];
    }
    return filtered;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              _goToQuizList();
            }
          },
        ),
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
            icon: const Icon(Icons.list_alt),
            tooltip: 'Liste des quiz',
            onPressed: _goToQuizList,
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
              : CustomScrollView(
                key: const PageStorageKey('adventure_scroll'),
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.amber.shade400),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 18,
                                  color: Colors.amber.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$_userPoints points',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Formation picker button
                  if (_availableFormationTitles.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.school,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _showFormationPicker,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 12,
                                  ),
                                  side: BorderSide(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedFormationTitle == null
                                          ? 'Choisir une formation'
                                          : _selectedFormationTitle!,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.8),
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Voir plus when many quizzes
                  SliverToBoxAdapter(
                    child:
                        (_selectedFormationTitle != null &&
                                !_showAllForFormation &&
                                _getDisplayQuizzes().length > 10)
                            ? Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed:
                                      () => setState(
                                        () => _showAllForFormation = true,
                                      ),
                                  icon: const Icon(Icons.expand_more),
                                  label: const Text('Voir plus'),
                                ),
                              ),
                            )
                            : const SizedBox.shrink(),
                  ),
                  // Toggle missions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Afficher les missions')),
                          Switch(
                            value: _showMissions,
                            onChanged: (v) => setState(() => _showMissions = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child:
                        _showMissions
                            ? DailyMissionsSection(
                              keyMission: _keyMission,
                              loginStreak: _loginStreak,
                              quizHistory: _quizHistory,
                            )
                            : const SizedBox.shrink(),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final displayQuizzes = _getDisplayQuizzes();
                      final quiz = displayQuizzes[index];
                      final isPlayed = _playedQuizIds.contains(
                        quiz.id.toString(),
                      );
                      final isUnlocked = _isQuizUnlocked(index);
                      final history =
                          _quizHistory.isNotEmpty
                              ? _quizHistory.firstWhere(
                                (h) => h.quiz.id == quiz.id.toString(),
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
                      if (history.totalQuestions > 0) {
                        final percent =
                            (history.correctAnswers / history.totalQuestions) *
                            100;
                        if (percent >= 100)
                          stars = 3;
                        else if (percent >= 70)
                          stars = 2;
                        else if (percent >= 40)
                          stars = 1;
                      }
                      final isLeft = index % 2 == 0;
                      // Couleur par catégorie de formation
                      Color categoryColor =
                          Theme.of(context).colorScheme.primary;
                      final cat =
                          (quiz.formation.categorie ?? '').trim().toLowerCase();
                      switch (cat) {
                        case 'bureautique':
                          categoryColor = const Color(0xFF3D9BE9);
                          break;
                        case 'langues':
                          categoryColor = const Color(0xFFA55E6E);
                          break;
                        case 'internet':
                          categoryColor = const Color(0xFFFFC533);
                          break;
                        case 'création':
                        case 'creation':
                          categoryColor = const Color(0xFF9392BE);
                          break;
                        default:
                          categoryColor = Theme.of(context).colorScheme.primary;
                      }
                      final nodeColor =
                          isPlayed
                              ? Colors.amber
                              : (isUnlocked ? categoryColor : Colors.grey);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isLeft)
                              Expanded(
                                child: _buildStepCard(
                                  quiz,
                                  isPlayed,
                                  isUnlocked,
                                  stars,
                                  nodeColor,
                                  onTap: () async {
                                    if (!(isUnlocked || isPlayed) ||
                                        quiz.questions.isEmpty)
                                      return;
                                    await _playSound('audio/click.mp3');
                                    final questions = await _quizRepository
                                        .getQuizQuestions(quiz.id);
                                    if (questions.isEmpty) return;
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => QuizSessionPage(
                                              quiz: quiz,
                                              questions: questions,
                                              quizAdventureEnabled:
                                                  widget.quizAdventureEnabled,
                                            ),
                                      ),
                                    );
                                    _loadInitialData();
                                  },
                                ),
                              ),
                            SizedBox(
                              width: 70,
                              child: Column(
                                children: [
                                  Container(
                                    height: 12,
                                    width: 2,
                                    color:
                                        index == 0
                                            ? Colors.transparent
                                            : Colors.grey.shade300,
                                  ),
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: nodeColor.withOpacity(
                                            isUnlocked ? 0.12 : 0.08,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: nodeColor,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      if (index == _avatarIndex)
                                        Positioned(
                                          top: -26,
                                          child: Container(
                                            key: _keyAvatarAnim,
                                            decoration: BoxDecoration(
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.yellow
                                                      .withOpacity(0.25),
                                                  blurRadius: 12,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                            child: Image.asset(
                                              _avatarPath,
                                              width: 36,
                                              height: 36,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Container(
                                    height: 60,
                                    width: 2,
                                    color:
                                        index == displayQuizzes.length - 1
                                            ? Colors.transparent
                                            : Colors.grey.shade300,
                                  ),
                                ],
                              ),
                            ),
                            if (isLeft)
                              Expanded(
                                child: _buildStepCard(
                                  quiz,
                                  isPlayed,
                                  isUnlocked,
                                  stars,
                                  nodeColor,
                                  onTap: () async {
                                    if (!isUnlocked || quiz.questions.isEmpty)
                                      return;
                                    await _playSound('audio/click.mp3');
                                    final questions = await _quizRepository
                                        .getQuizQuestions(quiz.id);
                                    if (questions.isEmpty) return;
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => QuizSessionPage(
                                              quiz: quiz,
                                              questions: questions,
                                              quizAdventureEnabled:
                                                  widget.quizAdventureEnabled,
                                            ),
                                      ),
                                    );
                                    _loadInitialData();
                                  },
                                ),
                              ),
                          ],
                        ),
                      );
                    }, childCount: _effectiveListLength()),
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
      floatingActionButton:
          _showBackToTopButton
              ? FloatingActionButton(
                onPressed: _scrollToTop,
                mini: true,
                backgroundColor: theme.colorScheme.primary,
                child: Icon(
                  Icons.arrow_upward,
                  color: theme.colorScheme.onPrimary,
                ),
              )
              : null,
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _goToQuizList() {
    if (!widget.quizAdventureEnabled) {
      // Adventure mode is disabled, stay in current page
      return;
    }
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => QuizPage(quizAdventureEnabled: false),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  Widget _buildStepCard(
    quiz_model.Quiz quiz,
    bool isPlayed,
    bool isUnlocked,
    int stars,
    Color accentColor, {
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final String levelRaw = quiz.niveau.trim();
    final String levelLabel =
        levelRaw.isEmpty
            ? 'Niveau inconnu'
            : (levelRaw[0].toUpperCase() + levelRaw.substring(1).toLowerCase());
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.8,
      child: InkWell(
        onTap: (isUnlocked || isPlayed) ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color:
                      isPlayed
                          ? accentColor.withOpacity(0.4)
                          : theme.dividerColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [accentColor.withOpacity(0.9), accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      isPlayed
                          ? Icons.emoji_events
                          : (isUnlocked ? Icons.star : Icons.lock),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.titre,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.school, size: 14, color: accentColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                quiz.formation.titre,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 14,
                              color: accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              levelLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                            // Mini stats si historique disponible
                            if (_quizHistory.isNotEmpty)
                              ...(() {
                                final h = _quizHistory.firstWhere(
                                  (qH) =>
                                      qH.quiz.id.toString() ==
                                      quiz.id.toString(),
                                  orElse:
                                      () => stats_model.QuizHistory(
                                        id: '',
                                        quiz: quiz,
                                        score: 0,
                                        completedAt: '',
                                        timeSpent: 0,
                                        totalQuestions: 0,
                                        correctAnswers: 0,
                                      ),
                                );
                                if (h.totalQuestions == 0) return <Widget>[];
                                final percent =
                                    ((h.correctAnswers / h.totalQuestions) *
                                            100)
                                        .round();
                                return <Widget>[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$percent% • ${h.correctAnswers}/${h.totalQuestions}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: Colors.blue.shade700,
                                          ),
                                    ),
                                  ),
                                ];
                              }()),
                          ],
                        ),
                        if (isPlayed)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed:
                                        () => _showQuizHistorySheet(quiz),
                                    icon: const Icon(Icons.history, size: 16),
                                    label: const Text('Historique'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      side: BorderSide(
                                        color: accentColor.withOpacity(0.6),
                                      ),
                                      foregroundColor: accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            if (!isUnlocked && !isPlayed)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(Icons.lock, size: 28, color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isQuizUnlocked(int index) {
    final list = _getDisplayQuizzes();
    if (index == 0) return true;
    final prevQuiz = list[index - 1];
    return _playedQuizIds.contains(prevQuiz.id.toString());
  }

  List<quiz_model.Quiz> _getDisplayQuizzes() {
    if (_selectedFormationTitle == null) return [];
    final full =
        _allQuizzes
            .where((q) => q.formation.titre == _selectedFormationTitle)
            .toList();
    if (_showAllForFormation) return full;
    if (full.length > 10) return full.sublist(0, 10);
    return full;
  }

  void _showFormationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final items = [..._availableFormationTitles];
        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(8),
          itemBuilder: (_, i) {
            final title = items[i];
            final selected = (_selectedFormationTitle == title);
            return ListTile(
              leading: Icon(
                Icons.school,
                color: selected ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text(title),
              trailing:
                  selected
                      ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                      : null,
              onTap: () {
                setState(() {
                  _selectedFormationTitle = title;
                  _showAllForFormation = false;
                });
                Navigator.pop(context);
              },
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: items.length,
        );
      },
    );
  }

  int _effectiveListLength() {
    if (_selectedFormationTitle == null) return 0;
    final full =
        _allQuizzes
            .where((q) => q.formation.titre == _selectedFormationTitle)
            .toList();
    if (_showAllForFormation) return full.length;
    return full.length > 10 ? 10 : full.length;
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

  void _showQuizHistorySheet(quiz_model.Quiz quiz) {
    final attempts =
        _quizHistory
            .where((h) => h.quiz.id.toString() == quiz.id.toString())
            .toList()
          ..sort((a, b) {
            // Most recent first by completedAt string parse
            DateTime parseDate(String s) {
              final d = DateTime.tryParse(s);
              return d ?? DateTime.fromMillisecondsSinceEpoch(0);
            }

            return parseDate(b.completedAt).compareTo(parseDate(a.completedAt));
          });
    final latestAttempts = attempts.take(5).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final theme = Theme.of(context);
        if (attempts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historique - ${quiz.titre}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                const Text('Aucune tentative trouvée.'),
              ],
            ),
          );
        }
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Historique - ${quiz.titre}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: latestAttempts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final h = latestAttempts[i];
                      final date = DateTime.tryParse(h.completedAt);
                      final dateLabel =
                          date != null
                              ? '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                              : h.completedAt;
                      final rate =
                          h.totalQuestions == 0
                              ? 0
                              : ((h.correctAnswers / h.totalQuestions) * 100)
                                  .round();
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary
                              .withOpacity(0.1),
                          foregroundColor: theme.colorScheme.primary,
                          child: const Icon(Icons.quiz, size: 18),
                        ),
                        title: Text('$rate% • ${h.score} pts'),
                        subtitle: Text(
                          '$dateLabel • ${h.correctAnswers}/${h.totalQuestions} • ${h.timeSpent}s',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DailyMissionsSection extends StatelessWidget {
  final GlobalKey? keyMission;
  final int loginStreak;
  final List<stats_model.QuizHistory> quizHistory;

  const DailyMissionsSection({
    Key? key,
    this.keyMission,
    required this.loginStreak,
    required this.quizHistory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Missions du jour',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Builder(
            builder: (context) {
              final mission1Completed = loginStreak >= 5;
              final mission2Completed = quizHistory.length >= 2;
              final starsTotal = quizHistory.fold(0, (sum, h) {
                final percent =
                    h.totalQuestions > 0
                        ? (h.correctAnswers / h.totalQuestions) * 100
                        : 0;
                if (percent >= 100) return sum + 3;
                if (percent >= 70) return sum + 2;
                if (percent >= 40) return sum + 1;
                return sum;
              });
              final mission3Completed = starsTotal >= 5;
              final mission4Completed = quizHistory.any(
                (h) => h.quiz.niveau.toLowerCase().contains('avanc'),
              );

              final List<Widget> pending = [];
              if (!mission1Completed)
                pending.add(
                  Container(
                    key: keyMission,
                    child: MissionCard(
                      mission: Mission(
                        id: 1,
                        title: 'Série de connexion',
                        description:
                            'Connecte-toi plusieurs jours d\'affilée pour gagner un badge.',
                        type: 'daily',
                        goal: 5,
                        reward: 'Badge',
                        progress: loginStreak,
                        completed: mission1Completed,
                        completedAt: null,
                      ),
                    ),
                  ),
                );
              if (!mission2Completed)
                pending.add(
                  MissionCard(
                    mission: Mission(
                      id: 2,
                      title: 'Réussir 2 quiz',
                      description:
                          'Complète 2 quiz aujourd\'hui pour gagner un badge.',
                      type: 'daily',
                      goal: 2,
                      reward: 'Badge',
                      progress:
                          quizHistory.length >= 2 ? 2 : quizHistory.length,
                      completed: mission2Completed,
                      completedAt: null,
                    ),
                  ),
                );
              if (!mission3Completed)
                pending.add(
                  MissionCard(
                    mission: Mission(
                      id: 3,
                      title: 'Obtenir 5 étoiles',
                      description: 'Cumule 5 étoiles sur tes quiz.',
                      type: 'daily',
                      goal: 5,
                      reward: 'Badge',
                      progress: starsTotal,
                      completed: mission3Completed,
                      completedAt: null,
                    ),
                  ),
                );
              if (!mission4Completed)
                pending.add(
                  MissionCard(
                    mission: Mission(
                      id: 4,
                      title: 'Jouer un quiz difficile',
                      description: 'Termine un quiz de niveau avancé.',
                      type: 'daily',
                      goal: 1,
                      reward: 'Points',
                      progress: mission4Completed ? 1 : 0,
                      completed: mission4Completed,
                      completedAt: null,
                    ),
                  ),
                );

              if (pending.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Row(
                    children: [
                      const Icon(Icons.celebration, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Toutes les missions du jour sont complétées !',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(children: [...pending, const SizedBox(height: 24)]);
            },
          ),
        ],
      ),
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

class _AnimatedQuizStepState extends State<_AnimatedQuizStep>
    with SingleTickerProviderStateMixin {
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
            color:
                widget.isUnlocked
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.grey,
          ),
        ),
      ],
    );
  }
}
