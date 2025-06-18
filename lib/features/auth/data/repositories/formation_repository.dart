import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/formation_model.dart';

class FormationRepository {
  final ApiClient apiClient;

  FormationRepository({required this.apiClient});

  Future<List<Formation>> getFormations() async {
    final response = await apiClient.get(AppConstants.catalogue_formation);
    print(response);
    final data = response.data;

    if (data is List) {
      return data.map((e) => Formation.fromJson(e)).toList();
    } else if (data is Map && data['data'] is List) {
      return (data['data'] as List).map((e) => Formation.fromJson(e)).toList();
    } else {
      throw Exception('Format de réponse inattendu');
    }
  }

  Future<List<Formation>> getFormationsByCategory(String category) async {
    final formations = await getFormations();
    return formations
        .where((formation) => formation.category.categorie == category)
        .toList();
  }

  Future<Formation> getFormationDetail(int id) async {
    final response = await apiClient.get('${AppConstants.catalogue_formation}/$id');
    final data = response.data['catalogueFormation'];

    return Formation.fromJson(data);
  }
}
