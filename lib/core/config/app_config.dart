// lib/core/config/environment.dart
abstract class Environment {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:5173',
  );

  static String get resetPasswordPath => '$baseUrl';
}