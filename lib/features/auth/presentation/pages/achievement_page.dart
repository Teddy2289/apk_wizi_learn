// lib/features/auth/presentation/pages/achievement_page.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/achievement_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/achievement_repository.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/achievement_badge_grid.dart';
import 'package:wizi_learn/features/auth/presentation/pages/all_achievements_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';

class AchievementPage extends StatefulWidget {
  const AchievementPage({Key? key}) : super(key: key);

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  late final AchievementRepository _repository;
  List<Achievement> _achievements = [];
  bool _isLoading = true;

  final GlobalKey _keyAllBadges = GlobalKey();
  final GlobalKey _keyBadgeGrid = GlobalKey();
  final GlobalKey _keyFirstBadge = GlobalKey();
  TutorialCoachMark? _tutorialCoachMark;

  @override
  void initState() {
    super.initState();
    final dio = Dio();
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(dio: dio, storage: storage);
    _repository = AchievementRepository(apiClient: apiClient);
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Retour',
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                RouteConstants.dashboard,
                (route) => false,
              );
            },
          ),
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
                  MaterialPageRoute(
                    builder: (_) => const AllAchievementsPage(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Voir le tutoriel',
              onPressed: _showTutorial,
            ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'Badges'), Tab(text: 'Missions accomplies')],
          ),
        ),
        body:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                )
                : TabBarView(
                  children: [
                    // Onglet Badges
                    _achievements.isEmpty
                        ? Center(
                          child: Text(
                            'Aucun badge débloqué pour le moment.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        )
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

                    // Onglet Missions accomplies
                    _buildCompletedMissionsTab(theme),
                  ],
                ),
      ),
    );
  }

  Widget _buildCompletedMissionsTab(ThemeData theme) {
    final missions =
        _achievements
            .where((a) => a.unlockedAt != null)
            .map(_mapAchievementToMission)
            .where((m) => m != null)
            .cast<_MissionViewModel>()
            .toList();

    if (missions.isEmpty) {
      return Center(
        child: Text(
          'Aucune mission accomplie pour le moment.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: missions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final m = missions[i];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(m.icon, color: theme.colorScheme.primary),
            ),
            title: Text(
              m.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(m.subtitle, style: theme.textTheme.bodySmall),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(height: 4),
                Text(
                  m.dateLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _MissionViewModel? _mapAchievementToMission(Achievement a) {
    final date = a.unlockedAt;
    final dateLabel =
        date != null ? '${date.day}/${date.month}/${date.year}' : '';
    switch (a.type.toLowerCase()) {
      case 'connexion_serie':
        return _MissionViewModel(
          icon: Icons.local_fire_department,
          title: 'Série de connexion',
          subtitle: a.name,
          dateLabel: dateLabel,
        );
      case 'quiz':
        return _MissionViewModel(
          icon: Icons.quiz,
          title: 'Premier quiz',
          subtitle: a.description,
          dateLabel: dateLabel,
        );
      case 'quiz_level':
        return _MissionViewModel(
          icon: Icons.trending_up,
          title: 'Premier quiz (${a.level ?? 'Niveau'})',
          subtitle: a.name,
          dateLabel: dateLabel,
        );
      case 'quiz_all':
      case 'quiz_all_level':
        return _MissionViewModel(
          icon: Icons.emoji_events,
          title: 'Tous les quiz',
          subtitle: a.name,
          dateLabel: dateLabel,
        );
      case 'points':
        return _MissionViewModel(
          icon: Icons.star,
          title: 'Points cumulés',
          subtitle: a.name,
          dateLabel: dateLabel,
        );
      case 'parrainage':
        return _MissionViewModel(
          icon: Icons.handshake,
          title: 'Parrainage',
          subtitle: a.description,
          dateLabel: dateLabel,
        );
      case 'action':
        return _MissionViewModel(
          icon: Icons.get_app,
          title: 'Action',
          subtitle: a.description,
          dateLabel: dateLabel,
        );
      default:
        return null;
    }
  }
}

class _MissionViewModel {
  final IconData icon;
  final String title;
  final String subtitle;
  final String dateLabel;
  _MissionViewModel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.dateLabel,
  });
}
