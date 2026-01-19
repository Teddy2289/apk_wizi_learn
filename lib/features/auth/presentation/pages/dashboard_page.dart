import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/presentation/pages/home_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/ranking_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/training_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/media_tutorial_page.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/custom_scaffold.dart';
import 'package:wizi_learn/features/auth/data/repositories/auth_repository.dart';
import 'package:wizi_learn/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:wizi_learn/features/formateur/presentation/pages/formateur_dashboard_page.dart';
import 'package:wizi_learn/features/formateur/presentation/pages/gestion_formations_page.dart';
import 'package:wizi_learn/features/formateur/presentation/pages/analytiques_page.dart';
import 'package:wizi_learn/features/formateur/presentation/pages/quiz_creator_page.dart';

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
  String? _userRole;
  bool _loading = true;
  late final AuthRepository _authRepository;

  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    
    _authRepository = AuthRepository(
      remoteDataSource: AuthRemoteDataSourceImpl(
        apiClient: apiClient,
        storage: const FlutterSecureStorage(),
      ),
      storage: const FlutterSecureStorage(),
    );
    
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = await _authRepository.getMe();
      debugPrint('DashboardPage: User role fetched: ${user.role}');
      setState(() {
        _userRole = user.role;
        _updatePagesList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('DashboardPage: Error loading user role: $e');
      setState(() {
        _userRole = 'apprenant'; // Fallback
        _updatePagesList();
        _loading = false;
      });
    }
  }

  void _updatePagesList() {
    if (_userRole == 'formateur') {
      _pages = [
        const FormateurDashboardPage(),
        const GestionFormationsPage(),
        const SizedBox(), // Placeholder for FAB
        const AnalytiquesPage(), // Replaces Ranking
        const QuizCreatorPage(), // Replaces Media
      ];
    } else {
      _pages = [
        const HomePage(),
        const TrainingPage(),
        const SizedBox(),
        const RankingPage(),
        const MediaTutorialPage(),
      ];
    }
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
    
    // Logic for redirection if specific tab is requested
    if (targetIndex == 2 && _userRole != 'formateur') {
         // Only redirect to quiz list if learner, for formateur index 2 is placeholder too but maybe different action
         // For now, keep generic logic for index 2 if mapped to FAB
       _currentIndex = 0; 
       WidgetsBinding.instance.addPostFrameCallback((_) {
        // If learner, go to quiz list. If formateur, do nothing or open create?
         Navigator.pushNamed(context, RouteConstants.quiz);
       });
    } else {
      _currentIndex = targetIndex;
    }
  }

  void _onTabSelected(int index) {
    if (index == 2) {
      // FAB Action
      if (_userRole == 'formateur') {
          // If formateur, FAB could be 'Create'
          // For now, let's open Quiz Creator as a separate page or specific action
          // Since index 4 is QuizCreatorPage (List), maybe FAB creates new?
          // Let's redirect to QuizCreatorPage for now or a specific 'Create' route
          // Or keep consistent: FAB opens "Quick Actions" or similar.
           Navigator.pushNamed(context, RouteConstants.quiz); // Or create route
      } else {
         Navigator.pushNamed(context, RouteConstants.quiz);
      }
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
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return CustomScaffold(
      body: _pages[_currentIndex],
      currentIndex: _currentIndex,
      onTabSelected: _onTabSelected,
      showBanner: true,
      quizAdventureEnabled: false,
      actions: [],
      // Pass role to CustomScaffold if it supports it, or handle BottomNavBar inside CustomScaffold via this role
      // But CustomScaffold is a wrapper. I need to modify CustomScaffold to accept 'role'
      // effectively it's 'role: _userRole ?? 'apprenant'' if I add the parameter.
      // I will add 'role' param to CustomScaffold in next step or now if already updated.
      // Assuming CustomScaffold is updated:
       role: _userRole ?? 'apprenant',
    );
  }
}
