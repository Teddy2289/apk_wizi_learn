class NotificationConstants {
  // Types de notifications
  static const String QUIZ_TYPE = 'quiz';
  static const String FORMATION_TYPE = 'formation';
  static const String MEDIA_TYPE = 'media';
  static const String BADGE_TYPE = 'badge';
  static const String SYSTEM_TYPE = 'system';

  // Topics FCM
  static const String QUIZ_TOPIC = 'quiz_notifications';
  static const String FORMATION_TOPIC = 'formation_notifications';
  static const String MEDIA_TOPIC = 'media_notifications';
  static const String GENERAL_TOPIC = 'general_notifications';

  // Actions de notifications
  static const String ACTION_VIEW_QUIZ = 'view_quiz';
  static const String ACTION_VIEW_FORMATION = 'view_formation';
  static const String ACTION_VIEW_MEDIA = 'view_media';
  static const String ACTION_VIEW_BADGE = 'view_badge';

  // Messages par défaut
  static const String DEFAULT_TITLE = 'Nouvelle notification';
  static const String DEFAULT_MESSAGE = 'Vous avez reçu une nouvelle notification';

  // Configuration des notifications locales
  static const String CHANNEL_ID = 'high_importance_channel';
  static const String CHANNEL_NAME = 'Notifications importantes';
  static const String CHANNEL_DESCRIPTION = 'Canal pour les notifications importantes';

  // Durées
  static const int NOTIFICATION_DURATION_SECONDS = 5;
  static const int TOAST_DURATION_SECONDS = 3;
} 