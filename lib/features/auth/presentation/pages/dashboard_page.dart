import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/presentation/pages/home_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/quiz_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/ranking_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/training_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/tutorial_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/custom_scaffold.dart';


class DashboardPage extends StatefulWidget {
  final int? initialIndex;
  final Map<String, dynamic>? arguments;


  const DashboardPage({
    super.key,
    this.initialIndex,
    this.arguments,
  });

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
    QuizPage(
      selectedTabIndex: _currentIndex,
      useCustomScaffold: _pageArguments?['useCustomScaffold'] ?? false,
      scrollToPlayed: _pageArguments?['scrollToPlayed'] ?? false,
      key: ValueKey(_pageArguments), // Important pour forcer le rebuild
    ),
    const RankingPage(),
    const TutorialPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    _pageArguments = widget.arguments;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        _currentIndex = args;
      } else if (args is Map<String, dynamic>) {
        _pageArguments = args;
        _currentIndex = args['selectedTabIndex'] ?? _currentIndex;
      }
      _initialized = true;
    }
  }

  void _onTabSelected(int index) {
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
      actions: [],
    );
  }
}