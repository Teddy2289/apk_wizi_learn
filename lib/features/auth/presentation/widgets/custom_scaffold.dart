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
import '../providers/notification_provider.dart';

class CustomScaffold extends StatefulWidget {
  final Widget body;
  final List<Widget>? actions;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool showBanner;
  final bool showBottomNavigationBar;

  const CustomScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTabSelected,
    this.actions,
    this.showBanner = true,
    this.showBottomNavigationBar = true,
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
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          _buildUserPointsAndNotifications(context),
          ...?widget.actions,
        ],
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
                onTap: widget.onTabSelected,
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
          // Notifications
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              final unreadCount = notifProvider.unreadCount;
              return IconButton(
                icon: Badge(
                  label: unreadCount > 0 ? Text('$unreadCount') : null,
                  isLabelVisible: unreadCount > 0,
                  child: const Icon(Icons.notifications),
                ),
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
      ),
    );
  }

  Widget _buildPointsBadge(int points, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade100, Colors.amber.shade200],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade800),
          const SizedBox(width: 6),
          Text(
            '$points pts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
              fontSize: 14,
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
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.card_giftcard,
              size: 30,
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.onPrimary,
                  ),
                  children: [
                    const TextSpan(text: 'Je parraine et je gagne '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: const Text(
                          '50 € ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 25,
                            fontFamily: 'Montserrat',
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
