import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileEditForm extends StatefulWidget {
  final Function()? onSuccess;
  final VoidCallback? onCancel;

  const ProfileEditForm({
    Key? key,
    this.onSuccess,
    this.onCancel,
  }) : super(key: key);

  @override
  State<ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends State<ProfileEditForm> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _villeController = TextEditingController();
  final _codePostalController = TextEditingController();
  final _adresseController = TextEditingController();

  bool _loading = false;
  bool _fetching = true;
  String? _error;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _villeController.dispose();
    _codePostalController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    // TODO: Implement API call to fetch profile
    // For now, simulate delay
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _prenomController.text = 'Jean';
      _nomController.text = 'Dupont';
      _emailController.text = 'jean.dupont@example.com';
      _telephoneController.text = '0612345678';
      _villeController.text = 'Paris';
      _codePostalController.text = '75001';
      _adresseController.text = '1 rue de la Paix';
      _fetching = false;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
      _success = false;
    });

    try {
      // TODO: Implement API call to update profile
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _success = true;
          _loading = false;
        });

        // Call success callback after delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            widget.onSuccess?.call();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Une erreur est survenue lors de la mise à jour';
          _loading = false;
        });
      }
    }
  }

  String? _validatePrenom(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le prénom est obligatoire';
    }
    if (value.trim().length < 2) {
      return 'Le prénom doit contenir au moins 2 caractères';
    }
    return null;
  }

  String? _validateNom(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom est obligatoire';
    }
    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    return null;
  }

  String? _validateTelephone(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^0[0-9]{9}$').hasMatch(value)) {
      return 'Format: 0XXXXXXXXX (10 chiffres)';
    }
    return null;
  }

  String? _validateCodePostal(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^[0-9]{5}$').hasMatch(value)) {
      return 'Le code postal doit contenir 5 chiffres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_fetching) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chargement du profil...'),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              // Title
              Row(
                children: [
                  const Icon(Icons.person, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Modifier mon profil',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Error message
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red[800]),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Success message
              if (_success) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Text(
                    '✅ Profil mis à jour avec succès !',
                    style: TextStyle(color: Colors.green[800]),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Prénom
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom *',
                  hintText: 'Votre prénom',
                  border: OutlineInputBorder(),
                ),
                enabled: !_loading,
                validator: _validatePrenom,
              ),
              const SizedBox(height: 16),

              // Nom
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  hintText: 'Votre nom',
                  border: OutlineInputBorder(),
                ),
                enabled: !_loading,
                validator: _validateNom,
              ),
              const SizedBox(height: 16),

              // Email (read-only)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFF9FAFB),
                  helperText: 'L\'email ne peut pas être modifié',
                ),
                enabled: false,
              ),
              const SizedBox(height: 16),

              // Téléphone
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  hintText: '0612345678',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                enabled: !_loading,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: _validateTelephone,
              ),
              const SizedBox(height: 16),

              // Adresse
              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  hintText: '1 rue de la Paix',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                enabled: !_loading,
              ),
              const SizedBox(height: 16),

              // Code Postal et Ville
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _codePostalController,
                      decoration: const InputDecoration(
                        labelText: 'Code Postal',
                        hintText: '75001',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_loading,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      validator: _validateCodePostal,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _villeController,
                      decoration: const InputDecoration(
                        labelText: 'Ville',
                        hintText: 'Paris',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_loading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _loading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Enregistrement...'),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.save, size: 20),
                                SizedBox(width: 8),
                                Text('Enregistrer'),
                              ],
                            ),
                    ),
                  ),
                  if (widget.onCancel != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading ? null : widget.onCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.close, size: 20),
                            SizedBox(width: 8),
                            Text('Annuler'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
