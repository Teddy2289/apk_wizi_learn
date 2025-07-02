import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/stats_model.dart';

class StatsRepository {
  final ApiClient apiClient;

  StatsRepository({required this.apiClient});

  Future<List<QuizHistory>> getQuizHistory({int page = 1, int limit = 10}) async {
    final response = await apiClient.get(
        '${AppConstants.quizHistory}?page=$page&limit=$limit'
    );
    final data = response.data as List;
    return data.map((e) => QuizHistory.fromJson(e)).toList();
  }


  Future<List<GlobalRanking>> getGlobalRanking() async {
    final response = await apiClient.get(AppConstants.globalRanking);
    final data = response.data as List;
    return data.map((e) => GlobalRanking.fromJson(e)).toList();
  }

  Future<QuizStats> getQuizStats() async {
    final response = await apiClient.get(AppConstants.quizStats);
    return QuizStats.fromJson(response.data);
  }
}
