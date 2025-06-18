import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/ranking.dart';

class RankingRepository {
  final Dio dio;

  RankingRepository({required this.dio});

  Future<Either<Failure, List<Ranking>>> getGlobalRanking() async {
    try {
      final response = await dio.get('/stagiaire/ranking/global');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final rankings = data.map((json) => Ranking(
          stagiaire: StagiaireInfo(
            id: json['stagiaire']['id'],
            prenom: json['stagiaire']['prenom'],
            image: json['stagiaire']['image'],
          ),
          totalPoints: json['totalPoints'],
          quizCount: json['quizCount'],
          averageScore: (json['averageScore'] as num).toDouble(),
          rang: json['rang'],
          level: json['level'],
        )).toList();
        
        return Right(rankings);
      }
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  Future<Either<Failure, Ranking>> getMyRanking() async {
    try {
      final response = await dio.get('/stagiaire/ranking/global');
      
      if (response.statusCode == 200) {
        final json = response.data;
        final ranking = Ranking(
          stagiaire: StagiaireInfo(
            id: json['stagiaire']['id'],
            prenom: json['stagiaire']['prenom'],
            image: json['stagiaire']['image'],
          ),
          totalPoints: json['totalPoints'],
          quizCount: json['quizCount'],
          averageScore: (json['averageScore'] as num).toDouble(),
          rang: json['rang'],
          level: json['level'],
        );
        
        return Right(ranking);
      }
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }
} 