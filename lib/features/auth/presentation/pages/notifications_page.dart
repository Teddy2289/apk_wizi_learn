import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/notification_model.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import 'dart:math';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).initialize();
    });
  }

  void _navigateToNotificationPage(
    BuildContext context,
    NotificationModel notification,
  ) {
    switch (notification.type) {
      case 'quiz':
        Navigator.pushReplacementNamed(
          context,
          RouteConstants.quiz,
          arguments: {'fromNotification': true},
        );
        break;
      case 'media':
        Navigator.pushReplacementNamed(
          context,
          RouteConstants.tutorialPage,
          arguments: {'fromNotification': true},
        );
        break;
      case 'formation':
        Navigator.pushReplacementNamed(
          context,
          RouteConstants.formations,
          arguments: {'fromNotification': true},
        );
        break;
      default:
        // Pas de navigation pour les autres types
        break;
    }
  }

  String _relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'il y a ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';

    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');

    if (diff.inDays == 0) return "Aujourd'hui à $hh:$mm";
    if (diff.inDays == 1) return 'Hier à $hh:$mm';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} $hh:$mm';
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'quiz':
        return Icons.star;
      case 'badge':
        return Icons.emoji_events;
      case 'formation':
        return Icons.menu_book;
      case 'media':
        return Icons.play_circle_fill;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  String _labelForType(String? type) {
    switch (type) {
      case 'quiz':
        return 'Quiz';
      case 'badge':
        return 'Badge';
      case 'formation':
        return 'Formation';
      case 'media':
        return 'Tutoriel';
      case 'system':
        return 'Système';
      default:
        return 'Notification';
    }
  }

  List<Widget> _buildNotificationList(
    BuildContext context,
    List<NotificationModel> notifications,
    NotificationProvider notifProvider,
  ) {
    final List<Widget> widgets = [];
    String? lastDateLabel;
    for (int i = 0; i < notifications.length; i++) {
      final notif = notifications[i];
      final date = notif.createdAt;
      String dateLabel;
      final now = DateTime.now();
      
      if (now.difference(date).inDays == 0) {
        dateLabel = "Aujourd'hui";
      } else if (now.difference(date).inDays == 1) {
        dateLabel = "Hier";
      } else {
        dateLabel = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }

      if (dateLabel != lastDateLabel) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              dateLabel.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.2,
                color: Colors.blue,
              ),
            ),
          ),
        );
        lastDateLabel = dateLabel;
      }

      widgets.add(
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + 40 * min(i, 8)),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: child,
            ),
          ),
          child: Dismissible(
            key: ValueKey(notif.id),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
            ),
            onDismissed: (_) => notifProvider.delete(notif.id),
            child: GestureDetector(
              onTap: () {
                notifProvider.markAsRead(notif.id);
                _navigateToNotificationPage(context, notif);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: notif.read 
                    ? const Color(0xFF1E1E1E).withOpacity(0.6) 
                    : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: notif.read 
                      ? Colors.white.withOpacity(0.05) 
                      : Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: notif.read 
                          ? Colors.white.withOpacity(0.05)
                          : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _iconForType(notif.type),
                        color: notif.read ? Colors.grey : Colors.blue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: notif.read ? Colors.grey[400] : Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _relativeTime(notif.createdAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notif.message,
                            style: TextStyle(
                              fontSize: 13,
                              color: notif.read ? Colors.grey[600] : Colors.grey[300],
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notifProvider, _) {
        final notifications = notifProvider.notifications;
        final unreadCount = notifProvider.unreadCount;
        final isLoading = notifProvider.isLoading;
        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pushReplacementNamed(context, RouteConstants.dashboard),
            ),
            title: const Text(
              'Notifications',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
            ),
            actions: [
              if (unreadCount > 0)
                IconButton(
                  icon: const Icon(Icons.done_all, color: Colors.blue),
                  onPressed: () => notifProvider.markAllAsRead(),
                  tooltip: 'Tout marquer comme lu',
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: isLoading && !notifProvider.initialized
              ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                  : RefreshIndicator(
                    onRefresh: notifProvider.refresh,
                    child:
                        notifications.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Aucune notification pour l'instant, tu es à jour !",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              children: _buildNotificationList(
                                context,
                                notifications,
                                notifProvider,
                              ),
                            ),
                  ),
        );
      },
    );
  }
}
