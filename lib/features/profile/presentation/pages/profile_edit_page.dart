import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:wizi_learn/features/profile/data/repositories/profile_repository.dart';
import 'package:wizi_learn/features/profile/presentation/widgets/profile_edit_form.dart';

/// Exemple d'utilisation du ProfileEditForm dans une page
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({Key? key}) : super(key: key);

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final ProfileRepository _repository;

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  void _initRepository() {
    final dio = Dio();
    const storage = FlutterSecureStorage();

    final dataSource = ProfileRemoteDataSourceImpl(
      dio: dio,
      baseUrl: AppConstants.baseUrl,
      getToken: () => storage.read(key: 'token'),
    );

    _repository = ProfileRepository(remoteDataSource: dataSource);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ProfileEditForm(
          repository: _repository,
          onSuccess: () {
            // Afficher message success
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profil mis à jour avec succès !'),
                backgroundColor: Colors.green,
              ),
            );
            // Retour à la page précédente après 1 seconde
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) Navigator.pop(context);
            });
          },
          onCancel: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
