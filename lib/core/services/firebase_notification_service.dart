import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
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
      print('Permissions accordées');
    } else {
      print('Permissions refusées');
    }

    // Obtenir le token FCM
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _sendTokenToServer(token);
    }

    // Écouter les changements de token
    _firebaseMessaging.onTokenRefresh.listen(_sendTokenToServer);
  }

  Future<void> _sendTokenToServer(String token) async {
    if (_apiClient == null) {
      print('ApiClient non disponible, token stocké localement: $token');
      await _storage.write(key: 'pending_fcm_token', value: token);
      return;
    }

    try {
      await _apiClient!.post('/fcm-token', data: {'token': token});
      print('Token FCM envoyé au serveur: $token');
      // Si l'envoi a réussi, supprime le token stocké
      await _storage.delete(key: 'pending_fcm_token');
    } catch (e) {
      print('Erreur lors de l\'envoi du token FCM: $e');
      // En cas d'échec, stocke le token pour un nouvel essai
      await _storage.write(key: 'pending_fcm_token', value: token);
    }
  }

  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message reçu en premier plan: ${message.messageId}');

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
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Gérer le tap sur la notification
    print('Notification tapée: ${response.payload}');
    // Ici vous pouvez naviguer vers une page spécifique
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
      print('Envoi du token FCM stocké localement après login: $token');
      await _sendTokenToServer(token);
    }
  }
}

// Handler pour les messages en arrière-plan (doit être en dehors de la classe)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Message reçu en arrière-plan: ${message.messageId}');
  // Ici vous pouvez traiter les notifications en arrière-plan
}
