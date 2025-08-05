import 'package:flutter/material.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';

class ThanksPage extends StatelessWidget {
  const ThanksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remerciements'),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.favorite, size: 50, color: Colors.red),
              SizedBox(height: 20),
              Text(
                'Nous tenons à remercier :',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                '- Notre équipe de développement\n'
                    '- Nos formateurs dévoués\n'
                    '- Tous nos utilisateurs fidèles',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}