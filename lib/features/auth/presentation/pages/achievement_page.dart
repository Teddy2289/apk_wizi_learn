import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/achievement_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/achievement_repository.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/achievement_badge_grid.dart';
import 'package:dio/dio.dart';

class AchievementPage extends StatefulWidget {
  const AchievementPage({Key? key}) : super(key: key);

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  late final AchievementRepository _repository;
  List<Achievement> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = AchievementRepository(dio: Dio());
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);
    final achievements = await _repository.getUserAchievements();
    setState(() {
      _achievements = achievements;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Badges'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
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
                      AchievementBadgeGrid(achievements: _achievements),
                    ],
                  ),
                ),
    );
  }
} 