import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/features/auth/data/models/notification_model.dart';
import 'package:wizi_learn/core/services/firebase_notification_service.dart';

class NotificationRepository {
  final ApiClient apiClient;
  final FirebaseNotificationService _firebaseService =
      FirebaseNotificationService();

  NotificationRepository({required this.apiClient});

  // Initialiser le service Firebase
  Future<void> initialize() async {
    await _firebaseService.initialize();
    // Définir l'ApiClient après l'initialisation
    _firebaseService.setApiClient(apiClient);
  }

  // Définir le callback pour les nouvelles notifications
  void setNotificationCallback(Function(NotificationModel) callback) {
    _firebaseService.onNotificationReceived = callback;
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    final response = await apiClient.get(AppConstants.notifications);
    final data = response.data['data'] as List;
    return data.map((e) => NotificationModel.fromJson(e)).toList();
  }

  Future<void> markAllAsRead() async {
    await apiClient.post(AppConstants.markAllNotificationsRead);
  }

  Future<void> markAsRead(int id) async {
    await apiClient.post(AppConstants.markNotificationAsRead(id));
  }

  Future<void> delete(int id) async {
    await apiClient.delete(AppConstants.deleteNotification(id));
  }

  Future<int> getUnreadCount() async {
    final response = await apiClient.get(AppConstants.notificationsUnreadCount);
    return response.data['count'] ?? 0;
  }

  // Méthodes FCM
  Future<String?> getFcmToken() async {
    return await _firebaseService.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseService.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseService.unsubscribeFromTopic(topic);
  }

  // Envoyer une notification de test
  Future<void> sendTestNotification() async {
    try {
      await apiClient.post(
        '/send-notification',
        data: {
          'user_id': 1, // Remplacer par l'ID de l'utilisateur connecté
          'title': 'Test notification',
          'body': 'Ceci est une notification de test',
        },
      );
    } catch (e) {
      print('Erreur lors de l\'envoi de la notification de test: $e');
    }
  }
}
