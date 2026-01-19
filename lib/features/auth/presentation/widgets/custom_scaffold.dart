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
  final String role;

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
    this.role = 'apprenant',
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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: CustomAppBar(
        backgroundColor: Colors.white,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          _buildUserPointsAndNotifications(context, isLandscape),
          ...?widget.actions,
        ],
        title: widget.appBarTitle,
        showLogo: widget.showLogo,
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          if (widget.showBanner) _buildSponsorshipBanner(context, isLandscape),
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
                isLandscape: isLandscape,
                role: widget.role,
              )
              : null,
    );
  }

  Widget _buildUserPointsAndNotifications(
    BuildContext context,
    bool isLandscape,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 4 : 8, // Réduit l'espacement en paysage
      ),
      child: Row(
        children: [
          // Points utilisateur (temps réel) - version compacte en paysage
          GestureDetector(
            onTap:
                () => Navigator.pushNamed(context, RouteConstants.achievement),
            child:
                isLandscape
                    ? _buildCompactPointsBadge(_currentPoints, context)
                    : _buildPointsBadge(_currentPoints, context),
          ),
          SizedBox(width: isLandscape ? 4 : 8), // Espacement réduit
          // NOUVEAU: Afficher les icônes d'accueil et quiz OU les notifications normales
          if (widget.showHomeAndQuizIcons == true) ...[
            // Icône Accueil
            _buildActionButton(
              icon: Icons.home_rounded,
              tooltip: 'Retour à l\'accueil',
              onPressed: widget.onHomePressed ?? () => _navigateToHome(context),
              isLandscape: isLandscape,
            ),
            SizedBox(width: isLandscape ? 2 : 4), // Espacement réduit
            // Icône Liste des quiz
            _buildActionButton(
              icon: Icons.quiz_rounded,
              tooltip: 'Liste des quiz',
              onPressed:
                  widget.onQuizListPressed ??
                  () => _navigateToQuizList(context),
              isLandscape: isLandscape,
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
                  isLandscape: isLandscape,
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
    required bool isLandscape,
  }) {
    final buttonSize = isLandscape ? 36.0 : 40.0; // Taille réduite en paysage
    final iconSize = isLandscape ? 18.0 : 20.0;

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          Center(
            child: IconButton(
              icon: Icon(icon, size: iconSize),
              tooltip: tooltip,
              onPressed: onPressed,
              padding: EdgeInsets.zero,
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: isLandscape ? 4 : 6,
              right: isLandscape ? 4 : 6,
              child: Container(
                width: isLandscape ? 14 : 16,
                height: isLandscape ? 14 : 16,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: isLandscape ? 1 : 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isLandscape ? 7 : 8,
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

  // Nouvelle version compacte pour le mode paysage
  Widget _buildCompactPointsBadge(int points, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$points',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorshipBanner(BuildContext context, bool isLandscape) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, RouteConstants.sponsorship),
      child: Container(
        margin: EdgeInsets.all(
          isLandscape ? 8 : 12,
        ), // Marge réduite en paysage
        padding: EdgeInsets.symmetric(
          vertical: isLandscape ? 8 : 12,
          horizontal: isLandscape ? 12 : 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isLandscape ? 12 : 16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: isLandscape ? 8 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isLandscape ? 6 : 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_giftcard_rounded,
                size: isLandscape ? 20 : 24,
                color: Colors.white,
              ),
            ),
            SizedBox(width: isLandscape ? 8 : 12),
            Expanded(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize:
                        isLandscape ? 13 : 15, // Texte plus petit en paysage
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
                          borderRadius: BorderRadius.circular(
                            isLandscape ? 6 : 8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: isLandscape ? 4 : 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: EdgeInsets.symmetric(
                          horizontal: isLandscape ? 6 : 8,
                          vertical: isLandscape ? 2 : 4,
                        ),
                        child: Text(
                          '50 €',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: isLandscape ? 16 : 18, // Taille réduite
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
