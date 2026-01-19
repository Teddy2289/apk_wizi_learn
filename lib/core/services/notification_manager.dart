import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:wizi_learn/core/services/navigation_service.dart';
import 'package:wizi_learn/core/services/badge_counter.dart';
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

  // Use a small BadgeCounter to encapsulate unread logic (testable)
  final BadgeCounter _badgeCounter = BadgeCounter();
  List<NotificationModel> _notifications = [];

  int get unreadCount => _badgeCounter.count;
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

      // Propager les changements de compteur vers le UI et badge
      _badgeCounter.onChanged = (count) {
        if (onUnreadCountChanged != null) onUnreadCountChanged!(count);
        _updateAppBadge();
      };

      debugPrint('NotificationManager initialisé avec succès');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du NotificationManager: $e');
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

    // Mettre à jour le compteur (utilise BadgeCounter pour la logique)
    if (!notification.read) {
      _badgeCounter.increment();
    }

    // Appeler le callback
    if (onNotificationReceived != null) {
      onNotificationReceived!(notification);
    }

    // Afficher une notification locale
    _showLocalNotification(notification);
  }

  Future<void> _showLocalNotification(NotificationModel notification) async {
    final AndroidNotificationDetails
    androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel',
      'Notifications importantes',
      channelDescription: 'Canal pour les notifications importantes',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      // Some Android launchers use the 'number' field to show a badge count on the app icon
      number: _badgeCounter.count,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Use a JSON payload so the tap handler can parse and navigate
    final payload = {'type': notification.type, 'id': notification.id};

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.message,
      platformChannelSpecifics,
      payload: payload.isNotEmpty ? jsonEncode(payload) : null,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapée: ${response.payload}');
    // Parse simple map-like payloads produced above and navigate
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        // Try to decode JSON payload (this is the most robust format)
        final payload = response.payload!;
        Map<String, dynamic> data;
        try {
          data = Map<String, dynamic>.from(jsonDecode(payload));
        } catch (_) {
          // Fallback: try to parse a Dart-like Map string (best-effort)
          final cleaned = payload.replaceAll("'", '"');
          data = Map<String, dynamic>.from(jsonDecode(cleaned));
        }

        if (data.containsKey('type')) {
          final type = data['type'];
          if (type == 'quiz' && data.containsKey('id')) {
            navigatorKey.currentState?.pushNamed(
              '/quiz',
              arguments: {'id': data['id']},
            );
          }
        } else if (data.containsKey('link')) {
          final String link = data['link'].toString();
          navigatorKey.currentState?.pushNamed(link);
        }
      } catch (e) {
        debugPrint('Erreur lors du parsing du payload local: $e');
      }
    }
  }

  // Méthodes publiques
  void setNotifications(List<NotificationModel> notifications) {
    _notifications = notifications;
    _badgeCounter.setCount(notifications.where((n) => !n.read).length);
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
      // decrement via BadgeCounter - it will call onUnreadCountChanged and update badge
      _badgeCounter.decrement();
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
    // reset counter via BadgeCounter
    _badgeCounter.reset();
  }

  void deleteNotification(int notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final wasUnread = !_notifications[index].read;
      _notifications.removeAt(index);
      if (wasUnread && _badgeCounter.count > 0) {
        _badgeCounter.decrement();
      }
    }
  }

  void deleteAllNotifications() {
    _notifications.clear();
    _badgeCounter.reset();
  }

  void _updateAppBadge() {
    try {
      final count = _badgeCounter.count;
      if (count > 0) {
        FlutterAppBadger.updateBadgeCount(count);
      } else {
        // remove badge if there are no unread notifications
        FlutterAppBadger.removeBadge();
      }
    } catch (e) {
      // Some launchers/platforms may not support badges — ignore errors
      debugPrint('Erreur lors de la mise à jour du badge: $e');
    }
  }

  Future<String?> getFcmToken() async {
    return await _firebaseService.getToken();
  }

  // Public helpers for debugging / external control
  /// Simulate receiving a notification (useful for debug UI)
  void simulateIncomingNotification(NotificationModel notification) {
    _handleNewNotification(notification);
  }

  /// Increment unread count (public API)
  void incrementUnread() {
    _badgeCounter.increment();
  }

  /// Decrement unread count (public API)
  void decrementUnread() {
    _badgeCounter.decrement();
  }

  /// Force-set unread count
  void setUnreadCount(int count) {
    _badgeCounter.setCount(count);
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseService.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseService.unsubscribeFromTopic(topic);
  }
}
