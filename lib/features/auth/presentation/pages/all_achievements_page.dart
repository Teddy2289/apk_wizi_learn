// lib/features/auth/presentation/pages/all_achievements_page.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/achievement_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/all_achievements_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/achievement_repository.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/achievement_badge_widget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class AllAchievementsPage extends StatefulWidget {
  const AllAchievementsPage({Key? key}) : super(key: key);

  @override
  State<AllAchievementsPage> createState() => _AllAchievementsPageState();
}

class _AllAchievementsPageState extends State<AllAchievementsPage> {
  late final AllAchievementsRepository _allRepo;
  late final AchievementRepository _userRepo;
  List<Achievement> _all = [];
  List<Achievement> _user = [];
  bool _isLoading = true;

@override
void initState() {
  super.initState();
  final dio = Dio();
  final storage = FlutterSecureStorage();
  final apiClient = ApiClient(dio: dio, storage: storage);
  _allRepo = AllAchievementsRepository(apiClient: apiClient);
  _userRepo = AchievementRepository(apiClient: apiClient);
  _loadAll();
}


  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final all = await _allRepo.getAllAchievements();
    final user = await _userRepo.getUserAchievements();
    setState(() {
      _all = all;
      _user = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tous les badges'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _all.length,
              itemBuilder: (context, index) {
                final badge = _all[index];
                final unlocked = _user.any((a) => a.id == badge.id && a.unlockedAt != null);
                return AchievementBadgeWidget(
                  achievement: badge,
                  unlocked: unlocked,
                );
              },
            ),
    );
  }
}
