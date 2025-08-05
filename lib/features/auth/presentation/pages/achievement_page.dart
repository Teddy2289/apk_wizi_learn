import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/achievement_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/achievement_repository.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/achievement_badge_grid.dart';
import 'package:dio/dio.dart';
import 'package:wizi_learn/features/auth/presentation/pages/all_achievements_page.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementPage extends StatefulWidget {
  const AchievementPage({Key? key}) : super(key: key);

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  late final AchievementRepository _repository;
  List<Achievement> _achievements = [];
  bool _isLoading = true;

  // GlobalKeys pour le tutoriel interactif
  final GlobalKey _keyAllBadges = GlobalKey();
  final GlobalKey _keyBadgeGrid = GlobalKey();
  final GlobalKey _keyFirstBadge = GlobalKey();
  TutorialCoachMark? _tutorialCoachMark;

  @override
  void initState() {
    super.initState();
    _repository = AchievementRepository(dio: Dio());
    _loadAchievements();
    _checkAndShowTutorial();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);
    final achievements = await _repository.getUserAchievements();
    setState(() {
      _achievements = achievements;
      _isLoading = false;
    });
  }

  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('badges_tutorial_seen') ?? false;
    if (!seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorial());
      await prefs.setBool('badges_tutorial_seen', true);
    }
  }

  void _showTutorial() {
    _tutorialCoachMark = TutorialCoachMark(
      targets: _buildTargets(),
      colorShadow: Colors.black,
      textSkip: 'Passer',
      paddingFocus: 8,
      opacityShadow: 0.8,
      onFinish: () {},
      onSkip: () {
        return true;
      },
    )..show(context: context);
  }

  List<TargetFocus> _buildTargets() {
    return [
      TargetFocus(
        identify: 'allbadges',
        keyTarget: _keyAllBadges,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Découvre tous les badges à débloquer ici.',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'badgegrid',
        keyTarget: _keyBadgeGrid,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              'Voici ta collection de badges débloqués.',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'firstbadge',
        keyTarget: _keyFirstBadge,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              'Chaque badge a une condition d’obtention. Tente de tous les débloquer !',
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
        title: const Text('Mes Badges'),
        centerTitle: true,
        actions: [
          IconButton(
            key: _keyAllBadges,
            icon: const Icon(Icons.grid_view),
            tooltip: 'Tous les badges',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllAchievementsPage()),
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
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
              : _achievements.isEmpty
              ? Center(child: Text('Aucun badge débloqué pour le moment.'))
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Débloque des badges en progressant dans tes quiz !',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    Container(
                      key: _keyBadgeGrid,
                      child: AchievementBadgeGrid(
                        achievements: _achievements,
                        keyFirstBadge: _keyFirstBadge,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
