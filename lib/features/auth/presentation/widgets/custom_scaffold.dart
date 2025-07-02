import 'package:flutter/material.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
import 'package:wizi_learn/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:wizi_learn/features/auth/data/models/stats_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/auth_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/notification_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/stats_repository.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/custom_app_bar.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/custom_bottom_navbar.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/custom_drawer.dart';

class CustomScaffold extends StatefulWidget {
  final Widget body;
  final List<Widget>? actions;
  final int currentIndex;
  final Function(int) onTabSelected;
  final bool showBanner;

  const CustomScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTabSelected,
    this.actions,
    this.showBanner = true,
  });

  @override
  State<CustomScaffold> createState() => _CustomScaffoldState();
}

class _CustomScaffoldState extends State<CustomScaffold> {
  late final NotificationRepository _notificationRepository;
  late final StatsRepository _statsRepository;
  late final AuthRepository _authRepository;

  Future<int>? _unreadCountFuture;
  Future<int>? _userPointsFuture;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );

    _notificationRepository = NotificationRepository(apiClient: apiClient);
    _statsRepository = StatsRepository(apiClient: apiClient);
    _authRepository = AuthRepository(
      remoteDataSource: AuthRemoteDataSourceImpl(
        apiClient: apiClient,
        storage: const FlutterSecureStorage(),
      ),
      storage: const FlutterSecureStorage(),
    );

    _loadData();
  }

  void _loadData() {
    setState(() {
      _unreadCountFuture = _loadUnreadCount();
      _userPointsFuture = _loadUserPoints();
    });
  }

  Future<int> _loadUnreadCount() async {
    try {
      return await _notificationRepository.getUnreadCount();
    } catch (e) {
      debugPrint('Error loading unread count: $e');
      return 0;
    }
  }

  Future<int> _loadUserPoints() async {
    try {
      final user = await _authRepository.getMe();
      debugPrint('User: ${user.stagiaire}');
      if (user.stagiaire?.id == null) return 0;

      final rankings = await _statsRepository.getGlobalRanking();
      final userRanking = rankings.firstWhere(
            (r) => r.stagiaire.id == user.stagiaire!.id.toString(),
        orElse: () => GlobalRanking(
          stagiaire: Stagiaire(id: '0', prenom: '', image: ''),
          totalPoints: 0,
          quizCount: 0,
          averageScore: 0,
          rang: 0,
        ),
      );

      return userRanking.totalPoints;
    } catch (e) {
      debugPrint('Error loading user points: $e');
      return 0;
    }
  }

  void refreshData() {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          // Points et notifications
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
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTabSelected,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedColor: Theme.of(context).colorScheme.primary,
        unselectedColor: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildUserPointsAndNotifications(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Points utilisateur
          FutureBuilder<int>(
            future: _userPointsFuture,
            builder: (context, snapshot) {
              final points = snapshot.data ?? 0;
              return _buildPointsBadge(points, context);
            },
          ),
          const SizedBox(width: 8),
          // Notifications
          FutureBuilder<int>(
            future: _unreadCountFuture,
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return IconButton(
                icon: Badge(
                  label: unreadCount > 0 ? Text('$unreadCount') : null,
                  isLabelVisible: unreadCount > 0,
                  child: const Icon(Icons.notifications),
                ),
                onPressed: () async {
                  await Navigator.pushNamed(context, RouteConstants.notifications);
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
          colors: [
            Colors.amber.shade100,
            Colors.amber.shade200,
          ],
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
          Icon(
            Icons.star_rounded,
            size: 18,
            color: Colors.amber.shade800,
          ),
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
                    const TextSpan(text: 'Parraine et gagne '),
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
                          '50€ ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
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