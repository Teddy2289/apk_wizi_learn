import 'package:flutter/material.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';

class UserManualPage extends StatelessWidget {
  const UserManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manuel d\'utilisation'),
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pushReplacementNamed(context, RouteConstants.dashboard)
        ),
        backgroundColor: isDarkMode ? theme.appBarTheme.backgroundColor : Colors.white,
        elevation: 1,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildManualSection(
              icon: Icons.school,
              title: 'Formations',
              content: 'Accédez à vos formations via l\'onglet "Mes formations".',
            ),
            _buildManualSection(
              icon: Icons.quiz,
              title: 'Quiz',
              content: 'Testez vos connaissances avec les quiz disponibles.',
            ),
            _buildManualSection(
              icon: Icons.timeline,
              title: 'Progression',
              content: 'Suivez votre progression dans l\'onglet dédié.',
            ),
            _buildManualSection(
              icon: Icons.contact_support,
              title: 'Support',
              content: 'Utilisez la page Contact pour toute question.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(content),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}