class AppConfig {
  final String baseUrl;
  final String baseUrlImg;
  final String parrainageBaseUrl;

  AppConfig({
    required this.baseUrl,
    required this.baseUrlImg,
    required this.parrainageBaseUrl,
  });

  // Configuration pour dev
  static final dev = AppConfig(
    baseUrl: "http://192.168.96.180:8000/api",
    baseUrlImg: "http://192.168.96.180:8000",
    parrainageBaseUrl: "http://192.168.96.180:8000",
  );

  // Configuration pour prod
  static final prod = AppConfig(
    baseUrl: "https://wizi-learn.com/api",
    baseUrlImg: "https://wizi-learn.com",
    parrainageBaseUrl: "https://wizi-learn.com",
  );
}

// Puis dans AppConstants:
class AppConstants {
  static late AppConfig config;

  static void initialize(AppConfig appConfig) {
    config = appConfig;
  }

  static String generateParrainageLink(String token) {
    return '${config.parrainageBaseUrl}/parrainage/$token';
  }

}