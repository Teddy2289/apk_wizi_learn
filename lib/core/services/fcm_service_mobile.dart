import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final storage = const FlutterSecureStorage();
  // Change this if your API base URL differs; kept default to existing host
  static const String _apiBaseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://wizi-learn.com',
  );

  Future<void> initFcm(BuildContext? context) async {
    // Demande la permission à l'utilisateur
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notifications refusées. Activez-les dans les paramètres pour recevoir des alertes.',
            ),
          ),
        );
      }
      return;
    }
    // Récupère le token
    String? token = await _messaging.getToken();
    if (token != null) {
      await sendTokenToBackend(token);
    }
    // Rafraîchissement du token
    _messaging.onTokenRefresh.listen(sendTokenToBackend);
  }

  Future<void> sendTokenToBackend(String token) async {
    String? authToken = await storage.read(key: 'token');
    try {
      await Dio().post(
        '$_apiBaseUrl/api/fcm-token',
        data: {'token': token},
        options: Options(
          headers: {
            if (authToken != null) 'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        ),
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi du token FCM au backend : $e');
    }
  }
}
