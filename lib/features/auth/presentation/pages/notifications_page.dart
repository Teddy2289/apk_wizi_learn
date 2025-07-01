import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/notification_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/notification_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationRepository repository;
  List<NotificationModel> _notifications = [];
  int unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    repository = NotificationRepository(apiClient: apiClient);
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      // Initialiser le service Firebase
      await repository.initialize();

      // Définir le callback pour les nouvelles notifications
      repository.setNotificationCallback(_onNewNotification);

      // Charger les données initiales
      await _loadData();
    } catch (e) {
      print('Erreur lors de l\'initialisation des notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onNewNotification(NotificationModel notification) {
    if (!mounted) return;
    setState(() {
      // Ajouter la nouvelle notification en haut de la liste
      _notifications.insert(0, notification);
      if (!notification.read) {
        unreadCount++;
      }
    });

    // Afficher un snackbar pour informer l'utilisateur
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.notifications, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Voir',
            textColor: Colors.white,
            onPressed: () {
              // Navigation vers la page appropriée selon le type
              _navigateToNotificationPage(notification);
            },
          ),
        ),
      );
    }
  }

  void _navigateToNotificationPage(NotificationModel notification) {
    switch (notification.type) {
      case 'quiz':
        Navigator.pushNamed(context, '/quiz');
        break;
      case 'media':
        Navigator.pushNamed(context, '/tutoriel');
        break;
      case 'formation':
        Navigator.pushNamed(context, '/formations');
        break;
      default:
        // Pas de navigation pour les autres types
        break;
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final notifications = await repository.fetchNotifications();
      final count = await repository.getUnreadCount();
      setState(() {
        _notifications = notifications;
        unreadCount = count;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _markAllAsRead() async {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].read) {
          _notifications[i] = NotificationModel(
            id: _notifications[i].id,
            title: _notifications[i].title,
            message: _notifications[i].message,
            read: true,
            createdAt: _notifications[i].createdAt,
            type: _notifications[i].type,
          );
        }
      }
      unreadCount = 0;
    });

    try {
      await repository.markAllAsRead();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toutes les notifications ont été marquées comme lues'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  void _deleteAll() async {
    setState(() {
      _notifications.clear();
      unreadCount = 0;
    });

    try {
      // Supprimer toutes les notifications du backend
      for (final notif in List<NotificationModel>.from(_notifications)) {
        await repository.delete(notif.id);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toutes les notifications ont été supprimées'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  // Méthode pour envoyer une notification de test
  void _sendTestNotification() async {
    try {
      await repository.sendTestNotification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification de test envoyée')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'envoi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            icon: const Icon(Icons.done_all),
            tooltip: 'Tout marquer comme lu',
            onPressed: unreadCount == 0 ? null : _markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Tout supprimer',
            onPressed: _notifications.isEmpty ? null : _deleteAll,
          ),
          IconButton(
            icon: const Icon(Icons.send),
            tooltip: 'Envoyer notification de test',
            onPressed: _sendTestNotification,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _refreshData,
                child:
                    _notifications.isEmpty
                        ? const Center(child: Text('Aucune notification'))
                        : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _notifications.length,
                          separatorBuilder:
                              (context, index) =>
                                  const Divider(height: 1, indent: 72),
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            return Dismissible(
                              key: ValueKey(notif.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (_) async {
                                setState(() {
                                  _notifications.removeAt(index);
                                  if (!notif.read && unreadCount > 0)
                                    unreadCount--;
                                });
                                try {
                                  await repository.delete(notif.id);
                                } catch (e) {
                                  print('Erreur lors de la suppression: $e');
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color:
                                      notif.read
                                          ? Colors.transparent
                                          : primaryColor.withOpacity(0.05),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Icon(
                                    Icons.notifications,
                                    color:
                                        notif.read
                                            ? colorScheme.onSurface
                                            : primaryColor,
                                  ),
                                  title: Text(
                                    notif.title,
                                    style: TextStyle(
                                      fontWeight:
                                          notif.read
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                      color:
                                          notif.read
                                              ? colorScheme.onSurface
                                              : primaryColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    notif.message,
                                    style: TextStyle(
                                      color:
                                          notif.read
                                              ? colorScheme.onSurface
                                                  .withOpacity(0.6)
                                              : primaryColor.withOpacity(0.8),
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${notif.createdAt.hour.toString().padLeft(2, '0')}:${notif.createdAt.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: colorScheme.onSurface
                                              .withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (!notif.read)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  onTap: () async {
                                    if (!notif.read) {
                                      setState(() {
                                        _notifications[index] =
                                            NotificationModel(
                                              id: notif.id,
                                              title: notif.title,
                                              message: notif.message,
                                              read: true,
                                              createdAt: notif.createdAt,
                                              type: notif.type,
                                            );
                                        unreadCount =
                                            unreadCount > 0
                                                ? unreadCount - 1
                                                : 0;
                                      });
                                      try {
                                        await repository.markAsRead(notif.id);
                                      } catch (e) {
                                        print(
                                          'Erreur lors du marquage comme lu: $e',
                                        );
                                      }
                                    }
                                    _navigateToNotificationPage(notif);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
              ),
    );
  }
}
