class NotificationConstants {
  // Types de notifications
  static const String quizType = 'quiz';
  static const String formationType = 'formation';
  static const String mediaType = 'media';
  static const String badgeType = 'badge';
  static const String systemType = 'system';

  // Topics FCM
  static const String quizTopic = 'quiz_notifications';
  static const String formationTopic = 'formation_notifications';
  static const String mediaTopic = 'media_notifications';
  static const String generalTopic = 'general_notifications';

  // Actions de notifications
  static const String actionViewQuiz = 'view_quiz';
  static const String actionViewFormation = 'view_formation';
  static const String actionViewMedia = 'view_media';
  static const String actionViewBadge = 'view_badge';

  // Messages par défaut
  static const String defaultTitle = 'Nouvelle notification';
  static const String defaultMessage = 'Vous avez reçu une nouvelle notification';

  // Configuration des notifications locales
  static const String channelId = 'high_importance_channel';
  static const String channelName = 'Notifications importantes';
  static const String channelDescription = 'Canal pour les notifications importantes';

  // Durées
  static const int notificationDurationSeconds = 5;
  static const int toastDurationSeconds = 3;
} 
