import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
import 'package:wizi_learn/features/auth/presentation/bloc/auth_event.dart';
import 'package:wizi_learn/features/auth/presentation/bloc/auth_state.dart';
import 'package:wizi_learn/features/auth/presentation/pages/auth/forgot_password.dart';
import '../../bloc/auth_bloc.dart';
import '../../components/auth_text_field.dart';
import 'package:wizi_learn/features/auth/presentation/constants/couleur_palette.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    // Palette de couleurs harmonisée avec splash_page.dart
    const Color kYellowLight = Color(0xFFFFF9C4); // jaune très clair
    const Color kYellow = Color(0xFFFFEB3B); // jaune
    const Color kOrange = Color(0xFFFF9800); // orange
    const Color kBrown = Color(0xFF8D6E63); // marron
    const Color kWhite = Colors.white;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kYellowLight, kWhite, kOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 24.0 : size.width * 0.2,
                  vertical: 24.0,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: kOrange.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Titre
                        Text(
                          'Bienvenue',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: kBrown,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Logo
                        Image.asset(
                          'assets/images/logo1.png',
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Connectez-vous à votre compte',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 32),
                        // Champ email
                        AuthTextField(
                          controller: _emailController,
                          labelText: 'Adresse email',
                          hintText: 'entrez@votre.email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre email';
                            }
                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+$',
                            ).hasMatch(value)) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Champ mot de passe
                        AuthTextField(
                          controller: _passwordController,
                          labelText: 'Mot de passe',
                          hintText: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey.shade500,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre mot de passe';
                            }
                            if (value.length < 6) {
                              return 'Minimum 6 caractères';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Lien mot de passe oublié
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(color: kOrange),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Bouton de connexion
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            if (state is AuthLoading) {
                              return const SizedBox(
                                height: 50,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      kOrange,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AuthBloc>().add(
                                      LoginEvent(
                                        email: _emailController.text.trim(),
                                        password:
                                            _passwordController.text.trim(),
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Gestion des états (erreur ou succès)
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthError) {
                  final isUnauthorized = state.message.contains('401');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isUnauthorized
                            ? 'Email ou mot de passe incorrect'
                            : state.message,
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } else if (state is Authenticated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Connexion réussie"),
                      backgroundColor: Colors.black,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  Future.microtask(() {
                    Navigator.pushReplacementNamed(
                      context,
                      RouteConstants.dashboard,
                    );
                  });
                }
              },
              child: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
