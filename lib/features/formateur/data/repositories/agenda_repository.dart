import 'package:flutter/foundation.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/agenda_model.dart';

class AgendaRepository {
  final ApiClient apiClient;

  AgendaRepository({required this.apiClient});

  Future<List<AgendaEvent>> getAgenda() async {
    try {
      final response = await apiClient.get('/agendas');
      
      // Handle the Collection format from backend
      List<dynamic> items = [];
      if (response.data is Map && response.data.containsKey('member')) {
        items = response.data['member'] as List;
      } else if (response.data is List) {
        items = response.data as List;
      }

      return items
          .map((json) => AgendaEvent.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur chargement agenda: $e');
      return [];
    }
  }
}
