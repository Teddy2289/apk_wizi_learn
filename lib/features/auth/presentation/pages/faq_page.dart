import 'package:flutter/material.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
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
          onPressed:
              () => Navigator.pushReplacementNamed(
            context,
            RouteConstants.dashboard,
          ),
        ),
        backgroundColor: isDarkMode ? theme.appBarTheme.backgroundColor : Colors.white,
        elevation: 1,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFAQItem(
              context,
              question: "Comment accéder à mes formations ?",
              answer: "Allez dans l'onglet 'Mes formations' pour voir toutes vos formations disponibles.",
            ),
            _buildFAQItem(
              context,
              question: "Comment gagner des points ?",
              answer: "Vous gagnez des points en complétant des quiz et en suivant vos formations.",
            ),
            _buildFAQItem(
              context,
              question: "Comment contacter le support ?",
              answer: "Utilisez la page 'Contact' dans le menu pour nous envoyer un message.",
            ),
            _buildFAQItem(
              context,
              question: "Comment réinitialiser mon mot de passe ?",
              answer: "Sur la page de connexion, cliquez sur 'Mot de passe oublié' pour recevoir un email de réinitialisation.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, {required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(answer),
          ),
        ],
      ),
    );
  }
}