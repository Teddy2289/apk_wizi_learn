import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('REQUEST[${options.method}] => FULL PATH: ${options.uri}');
    debugPrint('HEADERS: ${options.headers}');
    debugPrint('DATA: ${options.data}');
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('ERROR[${err.response?.statusCode}] => FULL PATH: ${err.requestOptions.uri}');
    debugPrint('ERROR TYPE: ${err.type}');
    debugPrint('ERROR MESSAGE: ${err.message}');
    if (err.response != null) {
      debugPrint('RESPONSE DATA: ${err.response?.data}');
    }
    super.onError(err, handler);
  }
}