import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wizi_learn/features/auth/data/models/notification_model.dart';
import 'package:wizi_learn/core/services/firebase_notification_service.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FirebaseNotificationService _firebaseService =
      FirebaseNotificationService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Callbacks pour les notifications
  Function(NotificationModel)? onNotificationReceived;
  Function(int)? onUnreadCountChanged;

  int _unreadCount = 0;
  List<NotificationModel> _notifications = [];

  int get unreadCount => _unreadCount;
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  Future<void> initialize() async {
    try {
      // Initialiser le service Firebase avec un ApiClient temporaire
      // L'ApiClient sera configuré plus tard via le repository
      await _firebaseService.initialize();

      // Configurer les callbacks
      _firebaseService.onNotificationReceived = _handleNewNotification;

      // Initialiser les notifications locales
      await _initializeLocalNotifications();

      print('NotificationManager initialisé avec succès');
    } catch (e) {
      print('Erreur lors de l\'initialisation du NotificationManager: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Configuration du canal Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notifications importantes',
      description: 'Canal pour les notifications importantes',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  void _handleNewNotification(NotificationModel notification) {
    // Ajouter la notification à la liste
    _notifications.insert(0, notification);

    // Mettre à jour le compteur
    if (!notification.read) {
      _unreadCount++;
      if (onUnreadCountChanged != null) {
        onUnreadCountChanged!(_unreadCount);
      }
    }

    // Appeler le callback
    if (onNotificationReceived != null) {
      onNotificationReceived!(notification);
    }

    // Afficher une notification locale
    _showLocalNotification(notification);
  }

  Future<void> _showLocalNotification(NotificationModel notification) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'Notifications importantes',
          channelDescription: 'Canal pour les notifications importantes',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.message,
      platformChannelSpecifics,
      payload: notification.type,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapée: ${response.payload}');
    // Ici vous pouvez naviguer vers une page spécifique selon le type
  }

  // Méthodes publiques
  void setNotifications(List<NotificationModel> notifications) {
    _notifications = notifications;
    _unreadCount = notifications.where((n) => !n.read).length;
    if (onUnreadCountChanged != null) {
      onUnreadCountChanged!(_unreadCount);
    }
  }

  void markAsRead(int notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].read) {
      _notifications[index] = NotificationModel(
        id: _notifications[index].id,
        title: _notifications[index].title,
        message: _notifications[index].message,
        read: true,
        createdAt: _notifications[index].createdAt,
        type: _notifications[index].type,
      );
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      if (onUnreadCountChanged != null) {
        onUnreadCountChanged!(_unreadCount);
      }
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].read) {
        _notifications[i] = NotificationModel(
          id: _notifications[i].id,
          title: _notifications[i].title,
          message: _notifications[i].message,
          read: true,
          createdAt: _notifications[i].createdAt,
          type: _notifications[i].type,
        );
      }
    }
    _unreadCount = 0;
    if (onUnreadCountChanged != null) {
      onUnreadCountChanged!(_unreadCount);
    }
  }

  void deleteNotification(int notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final wasUnread = !_notifications[index].read;
      _notifications.removeAt(index);
      if (wasUnread && _unreadCount > 0) {
        _unreadCount--;
        if (onUnreadCountChanged != null) {
          onUnreadCountChanged!(_unreadCount);
        }
      }
    }
  }

  void deleteAllNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    if (onUnreadCountChanged != null) {
      onUnreadCountChanged!(_unreadCount);
    }
  }

  Future<String?> getFcmToken() async {
    return await _firebaseService.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseService.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseService.unsubscribeFromTopic(topic);
  }
}
