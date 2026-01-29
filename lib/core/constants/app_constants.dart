class AppConstants {
  static const String appName = "Wizi Learn";
  // static const String baseUrl = "https://nodeapi.wizi-learn.com/api";
  static const String baseUrlImg = "https://api.wizi-learn.com";
  static const String baseUrl = "http://127.0.0.1:3000/api";
  static const String loginEndpoint = "/login";
  static const String logoutEndpoint = "/logout";
  static const String userEndpoint = "/user";
  static const String meEndpoint = "/me";
  static const String tokenKey = "auth_token";
  static const String userKey = "auth_user";
  static const String catalogueFormation = "/catalogueFormations/formations";
  static const String formationStagiaire = "/stagiaire/formations";
  static const String contact = "/stagiaire/contacts";
  static const String partner = "/stagiaire/partner";
  static const String quizHistory = "/quiz/history";
  static const String globalRanking = '/quiz/classement/global';
  static const String quizStats = '/quiz/stats';
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String markAllNotificationsRead = '/notifications/mark-all-read';
  static const String allAchievements = '/admin/achievements';
  static const String userAchievements = '/stagiaire/achievements';
  static const String updateUserPhotoEndpoint = "/user/photo";

  static String markNotificationAsRead(int id) => '/notifications/$id/read';
  static String deleteNotification(int id) => '/notifications/$id';

  static String astucesByFormation(int formationId) =>
      '$baseUrl/medias/formations/$formationId/astuces';

  static String tutorielsByFormation(int formationId) =>
      '$baseUrl/medias/formations/$formationId/tutoriels';
  static const Duration splashDuration = Duration(seconds: 2);

  static String _cleanPath(String path) {
    return path.startsWith('/') ? path.substring(1) : path;
  }

  static String _getCleanBase() {
    return baseUrlImg.endsWith('/')
        ? baseUrlImg.substring(0, baseUrlImg.length - 1)
        : baseUrlImg;
  }

  static String getMediaUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http://') || path.startsWith('https://')) return path;

    // Si le chemin commence par /api/medias/stream, il vient probablement de Node
    if (path.contains('/api/medias/stream/')) {
      final cleanBase = baseUrl.endsWith('/api') ? baseUrl.substring(0, baseUrl.length - 4) : baseUrl;
      return '$cleanBase/${_cleanPath(path)}';
    }

    return '${_getCleanBase()}/${_cleanPath(path)}';
  }

  static String getUserImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final mediaUrl = getMediaUrl(path);
    return mediaUrl.contains('?')
        ? '$mediaUrl&$timestamp'
        : '$mediaUrl?$timestamp';
  }

  static const String quizProgress = '/quiz/stats/progress';
  // Challenge mode endpoints (admin-configured)
  static const String challengeConfig = '/challenge/config';
  static const String challengeLeaderboard = '/challenge/leaderboard';
  static const String challengeEntries = '/challenge/entries';

  static String getAudioStreamUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return "";
    return '${_getCleanBase()}/media/stream/${_cleanPath(relativePath)}';
  }

  static String markMediaAsWatched(int mediaId) =>
      '$baseUrl/medias/$mediaId/watched';
  static const String formationsWithStatus =
      '$baseUrl/medias/formations-with-status';
}
