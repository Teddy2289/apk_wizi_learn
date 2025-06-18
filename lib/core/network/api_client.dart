import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/exceptions/api_exception.dart';
import '../constants/app_constants.dart';
import 'dio_interceptors.dart';

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient({required Dio dio, required FlutterSecureStorage storage})
      : _dio = dio,
        _storage = storage {
    _initDio();
  }

  void _initDio() {
    _dio.options = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    // Configuration spécifique Android
    if (!kIsWeb) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }

    _dio.interceptors.addAll([
      AuthInterceptor(storage: _storage),
      LoggingInterceptor(),
    ]);
  }

  // Méthodes d'API
  Future<Response> post(String path, {dynamic data, Options? options}) async {
    try {
      return await _dio.post(
        path,
        data: data,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response> get(String path, {Options? options, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(
        path,
        options: options,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response> put(String path, {dynamic data, Options? options}) async {
    try {
      return await _dio.put(
        path,
        data: data,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response> delete(String path, {dynamic data, Options? options}) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response> patch(String path, {dynamic data, Options? options}) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Dio get dio => _dio;
}