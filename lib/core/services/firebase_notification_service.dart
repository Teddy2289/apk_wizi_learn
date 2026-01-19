import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/core/services/navigation_service.dart';
import 'package:wizi_learn/features/auth/data/models/notification_model.dart';

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  ApiClient? _apiClient;

  // Callback pour les nouvelles notifications
  Function(NotificationModel)? onNotificationReceived;

  Future<void> initialize([ApiClient? apiClient]) async {
    _apiClient = apiClient;

    // Configuration des notifications locales
    await _initializeLocalNotifications();

    // Configuration FCM
    await _initializeFCM();

    // Écouter les messages en premier plan
    _setupForegroundMessageHandler();

    // Écouter les messages en arrière-plan
    _setupBackgroundMessageHandler();

    // Gérer les taps sur les notifications (lorsque l'app est en background ou cold start)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tap (onMessageOpenedApp): ${message.messageId}');
      _handleMessageNavigation(message.data);
    });

    // Cold start: vérifier si l'app a été ouverte par une notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App ouverte depuis une notification (initialMessage): ${message.messageId}');
        _handleMessageNavigation(message.data);
      }
    });
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

  Future<void> _initializeFCM() async {
    // Demander les permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Permissions accordées');
    } else {
      debugPrint('Permissions refusées');
    }

    // Obtenir le token FCM
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      // Ne pas envoyer le token ici, juste le stocker localement
      debugPrint('[FCM] Token obtenu après permission, stocké localement en attente de login: $token');
      await _storage.write(key: 'pending_fcm_token', value: token);
    }

    // Écouter les changements de token
    _firebaseMessaging.onTokenRefresh.listen((String refreshedToken) async {
      debugPrint('[FCM] Nouveau token FCM reçu (refresh), stocké localement en attente de login: $refreshedToken');
      await _storage.write(key: 'pending_fcm_token', value: refreshedToken);
    });
  }

  Future<void> _sendTokenToServer(String token) async {
    if (_apiClient == null) {
      debugPrint('ApiClient non disponible, token stocké localement: $token');
      await _storage.write(key: 'pending_fcm_token', value: token);
      return;
    }

    try {
      debugPrint('[FCM] Tentative d\'envoi du token au backend:');
      debugPrint('  URL: /fcm-token');
      // Impossible d'afficher les headers car ApiClient n'expose pas 'options'.
      debugPrint('  Headers: (non affichés, structure ApiClient inconnue)');
      debugPrint('  Data: {token: $token}');
      final response = await _apiClient!.post('/fcm-token', data: {'token': token});
      debugPrint('Réponse backend: statusCode=${response.statusCode}, data=${response.data}');
      debugPrint('Token FCM envoyé au serveur: $token');
      // Si l'envoi a réussi, supprime le token stocké
      await _storage.delete(key: 'pending_fcm_token');
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi du token FCM: $e');
      // En cas d'échec, stocke le token pour un nouvel essai
      await _storage.write(key: 'pending_fcm_token', value: token);
    }
  }

  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Message reçu en premier plan: ${message.messageId}');

      // Créer une notification locale
      _showLocalNotification(message);

      // Créer un modèle de notification
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch,
        title: message.notification?.title ?? 'Notification',
        message: message.notification?.body ?? '',
        read: false,
        createdAt: DateTime.now(),
        type: message.data['type'] ?? 'system',
      );

      // Appeler le callback si défini
      if (onNotificationReceived != null) {
        onNotificationReceived!(notification);
      }
    });
  }

  void _setupBackgroundMessageHandler() {
    // Register the background handler that shows a local notification
    // for data-only messages so the user can tap and open the app.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandlerShow);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
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

    // Ensure payload is a JSON string with data fields
    String payload = jsonEncode(message.data);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Gérer le tap sur la notification venant de flutter_local_notifications
    debugPrint('Notification tapée (local): ${response.payload}');
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _handleMessageNavigation(data);
      } catch (e) {
        debugPrint('Impossible de parser le payload de la notification: $e');
      }
    }
  }

  void _handleMessageNavigation(Map<String, dynamic> data) {
    if (data.containsKey('link') && data['link'] != null && data['link'].toString().isNotEmpty) {
      final String link = data['link'].toString();
      debugPrint('Navigation vers: $link');
      // Try to navigate. navigatorKey may be null if UI not ready yet.
      try {
        navigatorKey.currentState?.pushNamed(link);
      } catch (e) {
        debugPrint('Erreur lors de la navigation depuis la notification: $e');
      }
    } else if (data.containsKey('type')) {
      // Map types to routes if you use semantic types rather than full links
      final String type = data['type'].toString();
      debugPrint('Notification type: $type');
      // Example mapping: adapt to your actual routes
      if (type == 'quiz' && data.containsKey('quiz_id')) {
        navigatorKey.currentState?.pushNamed('/quiz', arguments: {'id': data['quiz_id']});
      }
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Méthode pour définir l'ApiClient après l'initialisation
  void setApiClient(ApiClient apiClient) {
    _apiClient = apiClient;
    // Tente d'envoyer un token FCM stocké localement si présent
    _sendPendingFcmTokenIfAny();
  }

  Future<void> _sendPendingFcmTokenIfAny() async {
    final token = await _storage.read(key: 'pending_fcm_token');
    if (token != null && _apiClient != null) {
      debugPrint('Envoi du token FCM stocké localement après login: $token');
      await _sendTokenToServer(token);
    }
  }
}

// Handler pour les messages en arrière-plan (doit être en dehors de la classe)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Message reçu en arrière-plan: ${message.messageId}');
  // Ici vous pouvez traiter les notifications en arrière-plan
}

// Dans le cas de messages 'data-only' délivrés alors que l'app est terminée,
// il est utile d'afficher une notification locale depuis l'handler en arrière-plan
// afin que l'utilisateur puisse cliquer dessus. On initialise local notifications
// dans cet isolate de background avant d'afficher.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandlerShow(RemoteMessage message) async {
  try {
    debugPrint('Background handler (with local notif) for message: ${message.messageId}');

    final FlutterLocalNotificationsPlugin fln = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await fln.initialize(initializationSettings);

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

    final payload = jsonEncode(message.data);

    await fln.show(
      message.hashCode,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: payload,
    );
  } catch (e) {
    debugPrint('Erreur dans background handler show notification: $e');
  }
}
