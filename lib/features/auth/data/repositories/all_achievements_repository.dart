import 'package:dio/dio.dart';
import 'package:wizi_learn/features/auth/data/models/achievement_model.dart';

class AllAchievementsRepository {
  final Dio dio;
  AllAchievementsRepository({required this.dio});

  Future<List<Achievement>> getAllAchievements() async {
    final response = await dio.get('/api/admin/achievements');
    if (response.data == null || response.data['achievements'] == null) {
      return [];
    }
    final List<dynamic> raw = response.data['achievements'];
    return raw.map((e) => Achievement.fromJson(e)).toList();
  }
} 