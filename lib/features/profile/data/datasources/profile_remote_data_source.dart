import 'package:dio/dio.dart';
import 'package:wizi_learn/core/exceptions/api_exception.dart';

abstract class ProfileRemoteDataSource {
  Future<Map<String, dynamic>> getProfile();
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final Dio dio;
  final String baseUrl;
  final Future<String?> Function() getToken;

  ProfileRemoteDataSourceImpl({
    required this.dio,
    required this.baseUrl,
    required this.getToken,
  });

  @override
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) throw ApiException(message: 'Token non disponible');

      final response = await dio.get(
        '$baseUrl/stagiaires/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final token = await getToken();
      if (token == null) throw ApiException(message: 'Token non disponible');

      final response = await dio.put(
        '$baseUrl/stagiaires/profile',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
