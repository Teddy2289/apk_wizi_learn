import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/repositories/parrainage_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/auth_repository.dart';
import 'package:wizi_learn/features/auth/data/datasources/auth_remote_data_source.dart';

import '../../../../core/constants/route_constants.dart';

class SponsorshipPage extends StatefulWidget {
  const SponsorshipPage({super.key});

  @override
  State<SponsorshipPage> createState() => _SponsorshipPageState();
}

class _SponsorshipPageState extends State<SponsorshipPage> {
  final _formKey = GlobalKey<FormState>();
  late final ParrainageRepository _parrainageRepo;
  late final AuthRepository _authRepository;

  // Contrôleurs pour les champs du formulaire
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();

  bool _isSubmitting = false;
  bool _isSuccess = false;
  bool _showSuccessModal = false;
  String? _parrainId; // Stocker l'ID du parrain
  bool _isLoadingUser = true;
  String? _userError;
  String? _userName;
  String? _userEmail;
  String? _userPhone;

  @override
  void initState() {
    super.initState();
    _initializeRepositories();
    _getConnectedUser(); // Récupérer l'utilisateur connecté
  }

  void _initializeRepositories() {
    final dio = Dio();
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(dio: dio, storage: storage);

    _parrainageRepo = ParrainageRepository(apiClient: apiClient);
    _authRepository = AuthRepository(
      remoteDataSource: AuthRemoteDataSourceImpl(
        apiClient: apiClient,
        storage: storage,
      ),
      storage: storage,
    );
  }

  // Méthode pour récupérer l'utilisateur connecté
  Future<void> _getConnectedUser() async {
    try {
      setState(() {
        _isLoadingUser = true;
        _userError = null;
      });

      final user = await _authRepository.getMe();

      // L'ID du parrain est l'ID de l'utilisateur connecté
      final connectedUserId = user.id?.toString();

      if (connectedUserId == null) {
        setState(() {
          _userError = 'Impossible de récupérer votre identifiant utilisateur';
          _isLoadingUser = false;
        });
        return;
      }

      // Concaténer username (majuscules) + prénom du stagiaire
      final userName = user.name?.toUpperCase() ?? '';
      final stagiairePrenom = user.stagiaire?.prenom ?? '';
      final fullName = userName.isNotEmpty && stagiairePrenom.isNotEmpty
          ? '$userName $stagiairePrenom'
          : userName.isNotEmpty
          ? userName
          : stagiairePrenom.isNotEmpty
          ? stagiairePrenom
          : 'Non renseigné';

      // Récupérer les informations directement
      setState(() {
        _parrainId = connectedUserId;
        _userName = fullName;
        _userEmail = user.email ?? 'Non renseigné';
        _userPhone = user.stagiaire?.telephone ?? 'Non renseigné';
        _isLoadingUser = false;
      });

      debugPrint("Parrain ID récupéré: $_parrainId");
      debugPrint("Nom complet: $_userName");

    } catch (e) {
      debugPrint("Erreur récupération user: $e");
      setState(() {
        _userError = 'Erreur lors de la récupération de vos informations';
        _isLoadingUser = false;
      });
    }
  }
  @override
  void dispose() {
    _parrainageRepo.dispose();
    _prenomController.dispose();
    _nomController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Vérifier que nous avons le parrain_id
    if (_parrainId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Impossible de récupérer votre identifiant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await _parrainageRepo.inscrireFilleul(
      prenom: _prenomController.text,
      nom: _nomController.text,
      telephone: _telephoneController.text,
      parrainId: _parrainId!, // Envoyer l'ID du parrain (utilisateur connecté)
    );

    setState(() {
      _isSubmitting = false;
    });

    if (result?['success'] == true) {
      // Réinitialiser le formulaire
      _formKey.currentState!.reset();

      // Afficher le modal de succès
      setState(() {
        _isSuccess = true;
        _showSuccessModal = true;
      });

    } else {
      // Afficher les erreurs détaillées
      String errorMessage = result?['message'] ?? 'Erreur lors de l\'inscription';

      // Afficher les erreurs de validation du backend
      if (result?['errors'] != null) {
        final errors = result?['errors'] as Map<String, dynamic>;
        final firstError = errors.values.first?.first?.toString();
        errorMessage = firstError ?? errorMessage;

        // Log détaillé pour le débogage
        debugPrint("Erreurs détaillées: $errors");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      _isSuccess = false;
      _showSuccessModal = false;
    });
    _formKey.currentState!.reset();
  }

  void _goToHome() {
    Navigator.pushReplacementNamed(
      context,
      RouteConstants.dashboard,
    );
  }

  void _closeSuccessModal() {
    setState(() {
      _showSuccessModal = false;
    });
  }

  void _retryUserLoading() {
    _getConnectedUser();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEB823),
        title: const Text('Programme de Parrainage'),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pushReplacementNamed(
            context,
            RouteConstants.dashboard,
          ),
        ),
      ),
      body: Stack(
        children: [
          _isLoadingUser
              ? _buildLoadingState(theme)
              : _userError != null
              ? _buildErrorState(theme)
              : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/share.png',
                    width: screenWidth * 0.7,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Parlez de nos formations à votre entourage (famille, amis, collègues et connaissances) et gagnez 50 €',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFEB823),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Parrainez et gagnez une carte cadeau de 50€ pour toute formation validée grâce à vous !",
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 30),

                // Informations du parrain (utilisateur connecté)
                _buildParrainInfo(context),
                const SizedBox(height: 30),

                // Formulaire d'inscription (seulement si pas de succès)
                if (!_isSuccess) _buildInscriptionForm(context),

                const SizedBox(height: 30),

                _buildStep(
                  context,
                  number: '1',
                  title: 'Remplissez le formulaire',
                  description: 'Saisissez les informations de votre filleul',
                ),
                _buildStep(
                  context,
                  number: '2',
                  title: 'Validez l\'inscription',
                  description: 'Soumettez le formulaire pour inscrire votre filleul',
                ),
                _buildStep(
                  context,
                  number: '3',
                  title: 'Vos amis sont contactés',
                  description: 'Nos commerciaux les contactent pour finaliser l\'inscription',
                ),
                _buildStep(
                  context,
                  number: '4',
                  title: 'Vous gagnez tous les deux',
                  description: 'Dès qu\'ils suivent leur première formation payante',
                ),
              ],
            ),
          ),

          // Modal de succès
          if (_showSuccessModal) _buildSuccessModal(context),
        ],
      ),
    );
  }

  // Méthode pour afficher les informations du parrain
  Widget _buildParrainInfo(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Vos informations (Parrain)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Nom complet', _userName ?? 'Non renseigné'),
            _buildInfoRow('Email', _userEmail ?? 'Non renseigné'),
            _buildInfoRow('Téléphone', _userPhone ?? 'Non renseigné'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modal de succès
  Widget _buildSuccessModal(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Demande envoyée avec succès !',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Votre demande de parrainage a été enregistrée avec succès. Nos commerciaux contacteront votre filleul rapidement.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _closeSuccessModal,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                      child: Text(
                        'Fermer',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _goToHome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEB823),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Accueil'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement de vos informations...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _userError ?? 'Erreur inconnue',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _retryUserLoading,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInscriptionForm(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inscrire un filleul',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Prénom
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom *',
                  border: OutlineInputBorder(),
                  hintText: 'Saisissez le prénom',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir le prénom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nom
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  border: OutlineInputBorder(),
                  hintText: 'Saisissez le nom',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir le nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Téléphone
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone *',
                  border: OutlineInputBorder(),
                  hintText: '06 12 34 56 78',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir le numéro de téléphone';
                  }
                  if (value.length < 8) {
                    return 'Numéro de téléphone invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Information sur le motif par défaut
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF32BBD3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Le motif "Soumission d\'une demande d\'inscription par parrainage" sera automatiquement enregistré.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEB823),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                      : const Text(
                    'Inscrire le filleul',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(
      BuildContext context, {
        required String number,
        required String title,
        required String description,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFFEB823),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}