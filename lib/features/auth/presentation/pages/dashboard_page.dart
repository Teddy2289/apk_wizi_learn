import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/presentation/pages/home_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/quiz_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/training_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/tutorial_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/custom_scaffold.dart';

import 'package:wizi_learn/features/auth/domain/user_entity.dart';

class DashboardPage extends StatefulWidget {
  final UserEntity user;
  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      const TrainingPage(),
      const QuizPage(),
      const Center(child: Text("Classement")),
      TutorialPage(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      body: _pages[_currentIndex],
      currentIndex: _currentIndex,
      onTabSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      // Vous pouvez ajouter des actions personnalisées si nécessaire
      actions: [
        // Ajoutez d'autres actions ici si besoin
      ],
      // Contrôler l'affichage du bandeau (true par défaut dans l'implémentation)
      showBanner: true,
    );
  }
}