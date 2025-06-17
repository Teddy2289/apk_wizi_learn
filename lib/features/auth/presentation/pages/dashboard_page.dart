import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/presentation/pages/home_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/quiz_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/training_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/tutorial_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/custom_scaffold.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  final List<Widget> titles = [
    const Text("Accueil"),
    const Text("Formation"),
    const Text("Quiz"),
    const Text("Classement"),
    const Text("Tutoriel"),
  ];

  final List<Widget> _pages = [
    const HomePage(),
    const TrainingPage(),
    const QuizPage(),
    const Center(child: Text("Classement")),
    const TutorialPage(),
  ];

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
    );
  }
}