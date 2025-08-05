import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wizi_learn/core/config/app_config.dart';
import 'package:wizi_learn/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wizi_learn/features/auth/presentation/bloc/auth_event.dart';
import 'package:wizi_learn/features/auth/presentation/bloc/auth_state.dart';
import 'package:wizi_learn/features/auth/presentation/components/auth_text_field.dart';
import 'package:wizi_learn/features/auth/presentation/constants/couleur_palette.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String get resetUrl => Environment.resetPasswordPath;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Réinitialisation du mot de passe',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Entrez votre email pour recevoir un lien de réinitialisation',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
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
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is ResetLinkSentSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Lien de réinitialisation envoyé par email',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  } else if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        context.read<AuthBloc>().add(
                          SendResetPasswordLink(
                            email: _emailController.text.trim(),
                            resetUrl: resetUrl,
                            isMobile: true,
                          ),
                        );
                      }
                    },
                    child: const Text('Envoyer le lien'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
