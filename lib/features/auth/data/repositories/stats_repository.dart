import 'package:flutter/cupertino.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/stats_model.dart';
import 'dart:async';

class StatsRepository {
  final ApiClient apiClient;
  final StreamController<int> _pointsStreamController = StreamController<int>.broadcast();
  Timer? _refreshTimer;

  StatsRepository({required this.apiClient});

  Future<List<QuizHistory>> getQuizHistory({int page = 1, int limit = 10}) async {
    final response = await apiClient.get('${AppConstants.quizHistory}?page=$page&limit=$limit');
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

  Stream<int> getLivePoints(String userId) {
    // Démarrer le timer si pas déjà fait
    _refreshTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchAndUpdatePoints(userId);
    });

    // Récupérer les points immédiatement
    _fetchAndUpdatePoints(userId);

    return _pointsStreamController.stream;
  }

  Future<void> _fetchAndUpdatePoints(String userId) async {
    try {
      final points = await _fetchUserPoints(userId);
      _pointsStreamController.add(points);
    } catch (e) {
      debugPrint('Error fetching points: $e');
    }
  }

  Future<int> _fetchUserPoints(String userId) async {
    final rankings = await getGlobalRanking();
    final userRanking = rankings.firstWhere(
          (r) => r.stagiaire.id == userId,
      orElse: () => GlobalRanking(
        stagiaire: Stagiaire(id: '0', prenom: '', nom: '', image: ''),
        formateurs: [],
        totalPoints: 0,
        quizCount: 0,
        averageScore: 0,
        rang: 0,
      ),
    );
    return userRanking.totalPoints;
  }

  void forceRefreshPoints(String userId) {
    _fetchAndUpdatePoints(userId);
  }

  void dispose() {
    _refreshTimer?.cancel();
    _pointsStreamController.close();
  }
}