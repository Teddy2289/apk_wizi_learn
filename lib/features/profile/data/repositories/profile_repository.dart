import 'package:wizi_learn/core/exceptions/api_exception.dart';
import 'package:wizi_learn/features/profile/data/datasources/profile_remote_data_source.dart';

class ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepository({required this.remoteDataSource});

  Future<Map<String, dynamic>> getProfile() async {
    try {
      return await remoteDataSource.getProfile();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Erreur lors de la récupération du profil');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String prenom,
    required String nom,
    String? telephone,
    String? ville,
    String? codePostal,
    String? adresse,
  }) async {
    try {
      final data = {
        'prenom': prenom,
        'nom': nom,
        if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
        if (ville != null && ville.isNotEmpty) 'ville': ville,
        if (codePostal != null && codePostal.isNotEmpty)
          'code_postal': codePostal,
        if (adresse != null && adresse.isNotEmpty) 'adresse': adresse,
      };

      return await remoteDataSource.updateProfile(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Erreur lors de la mise à jour du profil');
    }
  }
}
