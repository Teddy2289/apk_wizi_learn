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
  
  final List<Widget> _pages = [
    const HomePage(),
    const TrainingPage(),
    const MediaTutorialPage(),
    const RankingPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeFromArguments();
      _initialized = true;
    }
  }

  void _initializeFromArguments() {
    final args = widget.arguments ?? ModalRoute.of(context)?.settings.arguments;
    int targetIndex = _currentIndex;
    
    if (args is int) {
      targetIndex = args;
    } else if (args is Map<String, dynamic>) {
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
  }

  void _onTabSelected(int index) {
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
