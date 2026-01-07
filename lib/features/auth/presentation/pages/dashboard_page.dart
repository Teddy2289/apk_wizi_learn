import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/presentation/pages/home_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/ranking_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/training_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/media_tutorial_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/custom_scaffold.dart';

import 'package:wizi_learn/core/constants/route_constants.dart';

class DashboardPage extends StatefulWidget {
  final int? initialIndex;
  final Map<String, dynamic>? arguments;

  const DashboardPage({super.key, this.initialIndex, this.arguments});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late int _currentIndex;
  bool _initialized = false;
  Map<String, dynamic>? _pageArguments;

  // Remplacez la liste constante par une méthode qui crée les pages dynamiquement
  List<Widget> get _pages => [
    const HomePage(),
    const TrainingPage(),
    const SizedBox(), // Placeholder for Quiz (handled via navigation)
    const RankingPage(),
    const MediaTutorialPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    // Si l'index initial est 2 (Quiz), on le force à 0 pour le dashboard
    // La redirection se fera dans didChangeDependencies ou après le build
    if (_currentIndex == 2) {
      _currentIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamed(context, RouteConstants.quiz);
      });
    }
    _pageArguments = widget.arguments;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      int targetIndex = _currentIndex;
      
      if (args is int) {
        targetIndex = args;
      } else if (args is Map<String, dynamic>) {
        _pageArguments = args;
        targetIndex = args['selectedTabIndex'] ?? _currentIndex;
      }
      
      if (targetIndex == 2) {
        // Redirection vers la page Quiz indépendante
        _currentIndex = 0; // Default to Home underneath
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(context, RouteConstants.quiz);
        });
      } else {
        _currentIndex = targetIndex;
      }
      
      _initialized = true;
    }
  }

  void _onTabSelected(int index) {
    // Si on clique sur l'onglet Quiz (index 2), on navigue vers la page dédiée
    // au lieu de l'afficher dans le dashboard (pour éviter le double Scaffold/NavBar)
    if (index == 2) {
      Navigator.pushNamed(context, RouteConstants.quiz);
      return;
    }

    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      body: _pages[_currentIndex],
      currentIndex: _currentIndex,
      onTabSelected: _onTabSelected,
      showBanner: true,
      quizAdventureEnabled: false,
      actions: [],
    );
  }
}
