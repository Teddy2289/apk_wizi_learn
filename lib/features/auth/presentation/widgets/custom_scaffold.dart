import 'package:flutter/material.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
import 'package:wizi_learn/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:wizi_learn/features/auth/data/repositories/auth_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/stats_repository.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/custom_app_bar.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/custom_bottom_navbar.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/custom_drawer.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../pages/dashboard_page.dart';
import '../providers/notification_provider.dart';

class CustomScaffold extends StatefulWidget {
  final Widget body;
  final List<Widget>? actions;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool showBanner;
  final bool showBottomNavigationBar;
  final bool quizAdventureEnabled;
  final bool? showHomeAndQuizIcons;
  final VoidCallback? onHomePressed;
  final VoidCallback? onQuizListPressed;
  final String? appBarTitle;
  final bool showLogo;

  const CustomScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTabSelected,
    this.actions,
    this.showBanner = true,
    this.showBottomNavigationBar = true,
    this.quizAdventureEnabled = false,
    this.showHomeAndQuizIcons = false,
    this.onHomePressed,
    this.onQuizListPressed,
    this.appBarTitle,
    this.showLogo = true,
  });

  @override
  State<CustomScaffold> createState() => _CustomScaffoldState();
}

class _CustomScaffoldState extends State<CustomScaffold> {
  late final StatsRepository _statsRepository;
  late final AuthRepository _authRepository;
  late StreamSubscription<int> _pointsSubscription;
  int _currentPoints = 0;
  String? _userId;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );

    _statsRepository = StatsRepository(apiClient: apiClient);
    _authRepository = AuthRepository(
      remoteDataSource: AuthRemoteDataSourceImpl(
        apiClient: apiClient,
        storage: const FlutterSecureStorage(),
      ),
      storage: const FlutterSecureStorage(),
    );

    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final user = await _authRepository.getMe();
      if (user.stagiaire?.id != null) {
        _userId = user.stagiaire!.id.toString();
        _pointsSubscription = _statsRepository.getLivePoints(_userId!).listen((
          points,
        ) {
          if (mounted) {
            setState(() {
              _currentPoints = points;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing user data: $e');
    }

    _loadUnreadCount();
  }

  void _loadUnreadCount() {
    // No-op: unread count provided by NotificationProvider
  }

  @override
  void dispose() {
    _pointsSubscription.cancel();
    _statsRepository.dispose();
    super.dispose();
  }

  void refreshData() {
    _loadUnreadCount();
    if (_userId != null) {
      _statsRepository.forceRefreshPoints(_userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        backgroundColor: Colors.white,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          _buildUserPointsAndNotifications(context),
          ...?widget.actions,
        ],
        title: widget.appBarTitle,
        showLogo: widget.showLogo,
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          if (widget.showBanner) _buildSponsorshipBanner(context),
          Expanded(child: widget.body),
        ],
      ),
      bottomNavigationBar:
          widget.showBottomNavigationBar
              ? CustomBottomNavBar(
                currentIndex: widget.currentIndex,
                onTap: (index) {
                  widget.onTabSelected(index);
                },
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedColor: Theme.of(context).colorScheme.primary,
                unselectedColor: Colors.grey.shade600,
              )
              : null,
    );
  }

  Widget _buildUserPointsAndNotifications(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Points utilisateur (temps réel)
          GestureDetector(
            onTap:
                () => Navigator.pushNamed(context, RouteConstants.achievement),
            child: _buildPointsBadge(_currentPoints, context),
          ),
          const SizedBox(width: 8),

          // NOUVEAU: Afficher les icônes d'accueil et quiz OU les notifications normales
          if (widget.showHomeAndQuizIcons == true) ...[
            // Icône Accueil
            _buildActionButton(
              icon: Icons.home_rounded,
              tooltip: 'Retour à l\'accueil',
              onPressed: widget.onHomePressed ?? () => _navigateToHome(context),
            ),
            const SizedBox(width: 4),
            // Icône Liste des quiz
            _buildActionButton(
              icon: Icons.quiz_rounded,
              tooltip: 'Liste des quiz',
              onPressed:
                  widget.onQuizListPressed ??
                  () => _navigateToQuizList(context),
            ),
          ] else ...[
            // Notifications normales (comportement par défaut)
            Consumer<NotificationProvider>(
              builder: (context, notifProvider, _) {
                final unreadCount = notifProvider.unreadCount;
                return _buildActionButton(
                  icon: Icons.notifications_rounded,
                  tooltip: 'Notifications',
                  badgeCount: unreadCount,
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      RouteConstants.notifications,
                    );
                    refreshData();
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    int badgeCount = 0,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          Center(
            child: IconButton(
              icon: Icon(icon, size: 20),
              tooltip: tooltip,
              onPressed: onPressed,
              padding: EdgeInsets.zero,
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (context) => DashboardPage(
              initialIndex: 0,
              arguments: {
                'selectedTabIndex': 0,
                'fromNotification': true,
                'useCustomScaffold': true,
              },
            ),
      ),
      (route) => false,
    );
  }

  void _navigateToQuizList(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (context) => DashboardPage(
              initialIndex: 2,
              arguments: {
                'selectedTabIndex': 2,
                'fromNotification': true,
                'useCustomScaffold': true,
              },
            ),
      ),
      (route) => false,
    );
  }

  Widget _buildPointsBadge(int points, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '$points pts',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorshipBanner(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, RouteConstants.sponsorship),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_giftcard_rounded,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                    height: 1.3,
                  ),
                  children: [
                    const TextSpan(text: 'Je parraine et je gagne '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: const Text(
                          '50 €',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            fontFamily: 'Montserrat',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
