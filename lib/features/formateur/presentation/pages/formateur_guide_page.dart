import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';

class FormateurGuidePage extends StatelessWidget {
  const FormateurGuidePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: FormateurTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Guide d\'utilisation',
            style: TextStyle(
              color: FormateurTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          bottom: const TabBar(
            labelColor: FormateurTheme.accentDark,
            unselectedLabelColor: FormateurTheme.textSecondary,
            indicatorColor: FormateurTheme.accent,
            tabs: [
              Tab(text: 'Installation'),
              Tab(text: 'Interface'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GuideMarkdown(content: _installationContent),
            _GuideMarkdown(content: _interfaceContent),
          ],
        ),
      ),
    );
  }
}

class _GuideMarkdown extends StatelessWidget {
  final String content;

  const _GuideMarkdown({Key? key, required this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Markdown(
      data: content,
      styleSheet: MarkdownStyleSheet(
        h2: const TextStyle(
          color: FormateurTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 2,
        ),
        h3: const TextStyle(
          color: FormateurTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          height: 1.5,
        ),
        p: const TextStyle(
          color: FormateurTheme.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
        listBullet: const TextStyle(
          color: FormateurTheme.accentDark,
        ),
      ),
    );
  }
}

const String _installationContent = '''
## 📥 Téléchargement

L'application est fournie sous forme de fichier **APK**. Cliquez sur le lien de téléchargement fourni par votre administrateur. 

## ⚙️ Google Play Protect

Android peut afficher des avertissements pour les fichiers APK. 

1. Si une fenêtre **"Installation bloquée par Play Protect"** apparaît :
   - Cliquez sur **"Plus de détails"**.
   - Cliquez ensuite sur **"Installer quand même"**.
2. Si un message **"Envoyé pour analyse ?"** apparaît, cliquez sur **"Ne pas envoyer"**.

## 🚀 Installation locale

1. Ouvrez le fichier téléchargé.
2. Si besoin, autorisez l'installation depuis cette source dans les Paramètres.
3. Cliquez sur **Installer**.
''';

const String _interfaceContent = '''
## 🏠 Tableau de Bord

Dès votre connexion, vous visualisez vos statistiques clés :
- **Total Stagiaires**
- **Actifs (7j)**
- **Score Moyen**
- **Inactifs**

## 🧭 Navigation

- **Barre Basse** : Stats, Stagiaires, More, Tâches, Setup.
- **Menu Latéral** : Accès complet (Quiz, Classement, Vidéos).
- **Bouton (+)** : Création rapide de quiz ou de messages.

## 👥 Suivi Stagiaires

Consultez la progression circulaire (%) de chaque élève directement sur sa carte.
''';
