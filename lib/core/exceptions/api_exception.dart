import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  factory ApiException.fromDioError(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.cancel:
        return ApiException(message: "Requête annulée");
      case DioExceptionType.connectionTimeout:
        return ApiException(message: "Timeout de connexion au serveur");
      case DioExceptionType.receiveTimeout:
        return ApiException(message: "Timeout de réception de réponse");
      case DioExceptionType.sendTimeout:
        return ApiException(message: "Timeout d'envoi de données");
      case DioExceptionType.badCertificate:
        return ApiException(message: "Certificat SSL invalide");
      case DioExceptionType.badResponse:
        return ApiException.fromResponse(dioError.response!);
      case DioExceptionType.connectionError:
        return ApiException(message: "Erreur de connexion au serveur");
      case DioExceptionType.unknown:
        if (dioError.message?.contains("SocketException") ?? false) {
          return ApiException(message: "Pas de connexion Internet");
        }
        // Ajout de logging pour les erreurs inconnues
        debugPrint('UNKNOWN DIO ERROR:');
        debugPrint('Type: ${dioError.type}');
        debugPrint('Error: ${dioError.error}');
        debugPrint('Message: ${dioError.message}');
        debugPrint('Stacktrace: ${dioError.stackTrace}');
        return ApiException(
          message: "Erreur inconnue: ${dioError.message ?? 'Pas de message'}",
        );
    }
  }

  factory ApiException.fromResponse(Response response) {
    final statusCode = response.statusCode;
    final data = response.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? 'Something went wrong';
      return ApiException(message: message, statusCode: statusCode);
    }

    return ApiException(
      message: 'Received invalid status code: $statusCode',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => message;
}