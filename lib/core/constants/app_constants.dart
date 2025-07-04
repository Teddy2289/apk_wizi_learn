class AppConstants {
  static const String appName = "Wizi Learn";
  static const String baseUrl = "https://wizi-learn.com/api";
  static const String baseUrlImg = "https://wizi-learn.com/";
  // static const String baseUrl = "http://192.168.96.180:8000/api";
  // static const String baseUrlImg = "http://192.168.96.180:8000/";
  static const String loginEndpoint = "/login";
  static const String logoutEndpoint = "/logout";
  static const String userEndpoint = "/user";
  static const String meEndpoint = "/me";
  static const String tokenKey = "auth_token";
  static const String userKey = "auth_user";
  static const String catalogue_formation = "/catalogueFormations/formations";
  static const String formationStagiaire = "/stagiaire/formations";
  static const String contact = "/stagiaire/contacts";
  static const String quizHistory = "/quiz/history";
  static const String globalRanking = '/quiz/classement/global';
  static const String quizStats = '/quiz/stats';
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String markAllNotificationsRead = '/notifications/mark-all-read';

  static String markNotificationAsRead(int id) => '/notifications/$id/read';
  static String deleteNotification(int id) => '/notifications/$id';

  static String astucesByFormation(int formationId) =>
      '$baseUrl/medias/formations/$formationId/astuces';

  static String tutorielsByFormation(int formationId) =>
      '$baseUrl/medias/formations/$formationId/tutoriels';
  static const Duration splashDuration = Duration(seconds: 2);

  static String getUserImageUrl(String path) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$baseUrlImg/$path?$timestamp';
  }

  static const String quizProgress = '/quiz/stats/progress';

  static String getAudioStreamUrl(String relativePath) {
    relativePath = relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
    return '$baseUrlImg/media/stream/$relativePath';
  }


}
