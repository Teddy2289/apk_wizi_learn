import 'package:dio/dio.dart';
import 'package:wizi_learn/features/auth/data/models/mission_model.dart';

class MissionRepository {
  final Dio dio;
  MissionRepository({required this.dio});

  Future<List<Mission>> getMissions() async {
    final response = await dio.get('/missions');
    if (response.data == null || response.data['missions'] == null) {
      return [];
    }
    final List<dynamic> raw = response.data['missions'];
    return raw.map((e) => Mission.fromJson(e)).toList();
  }

  Future<void> updateProgress(int missionId, int progress) async {
    await dio.post('/missions/$missionId/progress', data: {'progress': progress});
  }

  Future<void> complete(int missionId) async {
    await dio.post('/missions/$missionId/complete');
  }
} 