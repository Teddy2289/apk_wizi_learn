import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('REQUEST[${options.method}] => FULL PATH: ${options.uri}');
    print('HEADERS: ${options.headers}');
    print('DATA: ${options.data}');
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print(
      'ERROR[${err.response?.statusCode}] => FULL PATH: ${err.requestOptions.uri}',
    );
    print('ERROR TYPE: ${err.type}');
    print('ERROR MESSAGE: ${err.message}');
    if (err.response != null) {
      print('RESPONSE DATA: ${err.response?.data}');
    }
    super.onError(err, handler);
  }
}
