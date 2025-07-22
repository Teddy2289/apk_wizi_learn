import 'package:dio/dio.dart';
import 'package:wizi_learn/features/auth/data/models/achievement_model.dart';

class AchievementRepository {
  final Dio dio;
  AchievementRepository({required this.dio});

  Future<List<Achievement>> getUserAchievements() async {
    final response = await dio.get('/api/stagiaire/achievements');
    print('Achievements API response: ${response.data}');
    if (response.data == null || response.data['achievements'] == null || response.data['achievements'] is! List) {
      return [];
    }
    final List<dynamic> raw = response.data['achievements'];
    return raw.map((e) => Achievement.fromJson(e)).toList();
  }
} 