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

  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();

  bool _isSubmitting = false;
  bool _isSuccess = false;
  bool _showSuccessModal = false;
  String? _parrainId;
  bool _isLoadingUser = true;
  String? _userError;
  String? _userName;
  String? _userEmail;
  String? _userPhone;

  // Couleurs - Utilisation du thème principal #FEB823 et bleu secondaire
  final Color _primaryColor = const Color(
    0xFFFEB823,
  ); // Couleur du thème (jaune/orange)
  final Color _secondaryColor = const Color(
    0xFF189FDB,
  ); // Bleu pour les éléments secondaires
  final Color _backgroundColor = Colors.white;
  final Color _surfaceColor = const Color(0xFFF8F9FA);
  final Color _textColor = Colors.black;
  final Color _hintColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _initializeRepositories();
    _getConnectedUser();
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

  Future<void> _getConnectedUser() async {
    try {
      setState(() {
        _isLoadingUser = true;
        _userError = null;
      });

      final user = await _authRepository.getMe();
      final connectedUserId = user.id.toString();

      final userName = user.name.toUpperCase() ?? '';
      final stagiairePrenom = user.stagiaire?.prenom ?? '';
      final fullName =
          userName.isNotEmpty && stagiairePrenom.isNotEmpty
              ? '$userName $stagiairePrenom'
              : userName.isNotEmpty
              ? userName
              : stagiairePrenom.isNotEmpty
              ? stagiairePrenom
              : 'Non renseigné';

      setState(() {
        _parrainId = connectedUserId;
        _userName = fullName;
        _userEmail = user.email ?? 'Non renseigné';
        _userPhone = user.stagiaire?.telephone ?? 'Non renseigné';
        _isLoadingUser = false;
      });
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
      parrainId: _parrainId!,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (result?['success'] == true) {
      _formKey.currentState!.reset();
      setState(() {
        _isSuccess = true;
        _showSuccessModal = true;
      });
    } else {
      String errorMessage =
          result?['message'] ?? 'Erreur lors de l\'inscription';
      if (result?['errors'] != null) {
        final errors = result?['errors'] as Map<String, dynamic>;
        final firstError = errors.values.first?.first?.toString();
        errorMessage = firstError ?? errorMessage;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
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
    Navigator.pushReplacementNamed(context, RouteConstants.dashboard);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor, // Couleur du thème
        elevation: 0,
        title: Text(
          'Programme de Parrainage',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          onPressed:
              () => Navigator.pushReplacementNamed(
                context,
                RouteConstants.dashboard,
              ),
        ),
      ),
      body: Stack(
        children: [
          _isLoadingUser
              ? _buildLoadingState()
              : _userError != null
              ? _buildErrorState()
              : SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header avec image
                    _buildHeaderSection(isSmallScreen),
                    const SizedBox(height: 24),

                    // Informations du parrain
                    _buildParrainInfo(),
                    const SizedBox(height: 24),

                    // Formulaire d'inscription
                    if (!_isSuccess) _buildInscriptionForm(isSmallScreen),
                    const SizedBox(height: 32),

                    // Section "Comment ça marche"
                    _buildHowItWorksSection(isSmallScreen),
                  ],
                ),
              ),

          // Modal de succès
          if (_showSuccessModal) _buildSuccessModal(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryColor.withOpacity(0.2),
        ), // Couleur du thème
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/share1.png',
            width: isSmallScreen ? 120 : 150,
            height: isSmallScreen ? 120 : 150,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            "Parrainez et Gagnez 50€ !",
            style: TextStyle(
              color: _primaryColor, // Couleur du thème
              fontSize: isSmallScreen ? 22 : 26,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Recommandez nos formations à votre entourage et recevez une carte cadeau de 50€ pour chaque inscription validée",
            style: TextStyle(
              color: _textColor,
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildParrainInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1), // Couleur du thème
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: _primaryColor,
                      size: 20,
                    ), // Couleur du thème
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Vos Informations',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _primaryColor, // Couleur du thème
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Nom complet', _userName ?? 'Non renseigné'),
              _buildInfoRow('Email', _userEmail ?? 'Non renseigné'),
              _buildInfoRow('Téléphone', _userPhone ?? 'Non renseigné'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _hintColor,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: _textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInscriptionForm(bool isSmallScreen) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _secondaryColor.withOpacity(0.1), // Bleu
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add,
                      color: _secondaryColor, // Bleu
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Inscrire un Filleul',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Champs du formulaire
              _buildFormField(
                controller: _prenomController,
                label: 'Prénom *',
                hintText: 'Saisissez le prénom',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              _buildFormField(
                controller: _nomController,
                label: 'Nom *',
                hintText: 'Saisissez le nom',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),

              _buildFormField(
                controller: _telephoneController,
                label: 'Téléphone *',
                hintText: '06 12 34 56 78',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.05), // Couleur du thème
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.2),
                  ), // Couleur du thème
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: _primaryColor,
                      size: 20,
                    ), // Couleur du thème
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Le motif "Soumission d\'une demande d\'inscription par parrainage" sera automatiquement enregistré.',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _secondaryColor, // Bleu pour le bouton principal
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Inscrire le Filleul',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: _hintColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _hintColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _primaryColor,
            width: 2,
          ), // Couleur du thème
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: _textColor),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ce champ est obligatoire';
        }
        if (label.contains('Téléphone') && value.length < 8) {
          return 'Numéro de téléphone invalide';
        }
        return null;
      },
    );
  }

  Widget _buildHowItWorksSection(bool isSmallScreen) {
    final List<Map<String, String>> steps = [
      {
        'number': '1',
        'title': 'Remplissez le formulaire',
        'description':
            'Saisissez les informations de votre filleul (nom, prénom, téléphone)',
      },
      {
        'number': '2',
        'title': 'Validez l\'inscription',
        'description': 'Soumettez le formulaire pour inscrire votre filleul',
      },
      {
        'number': '3',
        'title': 'Contact commercial',
        'description':
            'Nos commerciaux contactent votre filleul pour finaliser l\'inscription',
      },
      {
        'number': '4',
        'title': 'Récompense de 50€',
        'description':
            'Vous recevez 50€ de carte cadeau dès qu\'il suit sa première formation',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1), // Couleur du thème
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.help_outline,
                color: _primaryColor,
                size: 20,
              ), // Couleur du thème
            ),
            const SizedBox(width: 12),
            Text(
              'Comment ça marche ?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _primaryColor, // Couleur du thème
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Liste numérotée simple
        Column(
          children:
              steps.map((Map<String, String> step) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _primaryColor.withOpacity(0.1),
                    ), // Couleur du thème
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _primaryColor, // Couleur du thème
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            step['number']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step['title']!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _textColor,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              step['description']!,
                              style: TextStyle(color: _hintColor, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildSuccessModal() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1), // Couleur du thème
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: _primaryColor,
                  size: 48,
                ), // Couleur du thème
              ),
              const SizedBox(height: 20),
              Text(
                'Demande Envoyée !',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _primaryColor, // Couleur du thème
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Votre demande de parrainage a été enregistrée avec succès. Nos commerciaux contacteront votre filleul rapidement.',
                style: TextStyle(color: _textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _closeSuccessModal,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: _hintColor),
                      ),
                      child: Text(
                        'Fermer',
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _goToHome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _secondaryColor, // Bleu pour le bouton
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Accueil',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1), // Couleur du thème
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                _primaryColor,
              ), // Couleur du thème
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Chargement de vos informations...',
            style: TextStyle(color: _textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 40, color: Colors.red),
            ),
            const SizedBox(height: 20),
            Text(
              'Erreur de chargement',
              style: TextStyle(fontWeight: FontWeight.w600, color: _textColor),
            ),
            const SizedBox(height: 12),
            Text(
              _userError ?? 'Erreur inconnue',
              style: TextStyle(color: _hintColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _retryUserLoading,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor, // Couleur du thème
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
