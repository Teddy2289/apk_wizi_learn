import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/notification_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/notification_repository.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/help_dialog.dart';
import 'dart:math';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

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
        dateLabel =
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
      if (dateLabel != lastDateLabel) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              dateLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
        lastDateLabel = dateLabel;
      }
      widgets.add(
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 350 + 30 * min(i, 10)),
          builder:
              (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              ),
          child: Dismissible(
            key: ValueKey(notif.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => notifProvider.delete(notif.id),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color:
                    notif.read
                        ? Colors.transparent
                        : Theme.of(context).primaryColor.withOpacity(0.07),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor:
                      notif.read
                          ? Colors.grey.shade200
                          : Theme.of(context).primaryColor.withOpacity(0.15),
                  child: Icon(
                    _iconForType(notif.type),
                    color:
                        notif.read
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                    semanticLabel: _labelForType(notif.type),
                  ),
                  radius: 22,
                ),
                title: Text(
                  notif.title,
                  style: TextStyle(
                    fontWeight:
                        notif.read ? FontWeight.normal : FontWeight.bold,
                    color:
                        notif.read
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).primaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.message,
                      style: TextStyle(
                        color:
                            notif.read
                                ? Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7)
                                : Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.85),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _relativeTime(notif.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!notif.read)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  notifProvider.markAsRead(notif.id);
                  _navigateToNotificationPage(context, notif);
                },
                isThreeLine: true,
                visualDensity: VisualDensity.compact,
                minVerticalPadding: 8,
                minLeadingWidth: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor:
                    notif.read
                        ? Colors.transparent
                        : Theme.of(context).primaryColor.withOpacity(0.04),
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
          appBar: AppBar(
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed:
                  () => Navigator.pushReplacementNamed(
                    context,
                    RouteConstants.dashboard,
                  ),
            ),
            title: Row(
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: 'Voir le tutoriel',
                onPressed:
                    () => showStandardHelpDialog(
                      context,
                      steps: const [
                        '1. Balayez une notification pour la supprimer.',
                        '2. Touchez une notification pour ouvrir la page liée.',
                        '3. Utilisez les actions en haut pour tout lire/supprimer.',
                      ],
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.done_all),
                tooltip: 'Tout marquer comme lu',
                onPressed:
                    unreadCount == 0
                        ? null
                        : () => notifProvider.markAllAsRead(),
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Tout supprimer',
                onPressed:
                    notifications.isEmpty
                        ? null
                        : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (ctx) => AlertDialog(
                                  title: const Text(
                                    'Supprimer toutes les notifications ?',
                                  ),
                                  content: const Text(
                                    'Cette action est irréversible. Confirmer la suppression de toutes les notifications ?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(ctx, false),
                                      child: const Text('Annuler'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Supprimer'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                          );
                          if (confirm == true) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder:
                                  (ctx) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                            );
                            await notifProvider.deleteAll();
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
              ),
            ],
          ),
          body:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
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
                                    'Aucune notification pour l\'instant, tu es à jour !',
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
