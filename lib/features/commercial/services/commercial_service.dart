import 'package:dio/dio.dart';
import '../models/user.dart';
import '../models/online_user.dart';
import '../models/stats_data.dart';
import '../models/notification_history.dart';

class CommercialService {
  final Dio _dio;
  final String baseUrl;

  CommercialService(this._dio, {required this.baseUrl});

  /// Send email to selected users
  Future<void> sendEmail({
    required List<String> userIds,
    required String subject,
    required String message,
  }) async {
    try {
      await _dio.post(
        '$baseUrl/email',
        data: {
          'userIds': userIds,
          'subject': subject,
          'message': message,
        },
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'email: $e');
    }
  }

  /// Send push notification to segment
  Future<void> sendNotification({
    required String segment,
    required String message,
  }) async {
    try {
      await _dio.post(
        '$baseUrl/notify',
        data: {
          'segment': segment,
          'message': message,
        },
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de la notification: $e');
    }
  }

  /// Get statistics data
  Future<StatsData> getStats({
    required String range,
    required String metric,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/commercial/stats/dashboard',
        queryParameters: {
          'range': range,
          'metric': metric,
        },
      );
      return StatsData.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors du chargement des statistiques: $e');
    }
  }

  /// Get online users list
  Future<List<OnlineUser>> getOnlineUsers() async {
    try {
      final response = await _dio.get('$baseUrl/online-users');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => OnlineUser.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des utilisateurs en ligne: $e');
    }
  }

  /// Get all users (for email selection)
  Future<List<User>> getUsers({String? search}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/users',
        queryParameters: search != null ? {'search': search} : null,
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des utilisateurs: $e');
    }
  }

  /// Get notification history
  Future<List<NotificationHistory>> getNotificationHistory({
    String? type,
    int? perPage,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/notification-history',
        queryParameters: {
          if (type != null) 'type': type,
          if (perPage != null) 'perPage': perPage,
        },
      );

      // Handle both array and paginated responses
      final data = response.data;
      final List<dynamic> items = data is List
          ? data
          : (data['data'] as List<dynamic>? ?? []);

      return items.map((json) => NotificationHistory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement de l\'historique: $e');
    }
  }
}
