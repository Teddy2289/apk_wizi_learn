import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/notification_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/notification_repository.dart';
import 'dart:async';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository repository;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _initialized = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;

  NotificationProvider({required this.repository});

  Future<void> initialize() async {
    if (_initialized) return;
    _isLoading = true;
    notifyListeners();
    try {
      await repository.initialize();
      repository.setNotificationCallback(_onNewNotification);
      await refresh();
      _initialized = true;
    } catch (e) {
      // Optionally handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      final notifs = await repository.fetchNotifications();
      final count = await repository.getUnreadCount();
      _notifications = notifs;
      _unreadCount = count;
    } catch (e) {
      // Optionally handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Debounce refresh calls so rapid FCM bursts do not overload the API
  Timer? _refreshTimer;
  Duration _refreshDebounceDuration = const Duration(seconds: 2);

  void _onNewNotification(NotificationModel notification) {
    // Update local state immediately for snappy UI
    _notifications.insert(0, notification);
    if (!notification.read) _unreadCount++;
    notifyListeners();

    // Schedule a debounced refresh from server to ensure canonical state
    _refreshTimer?.cancel();
    _refreshTimer = Timer(_refreshDebounceDuration, () async {
      try {
        await refresh();
      } catch (e) {
        // If refresh fails, keep local state — will retry on next manual refresh
      }
    });
  }

  Future<void> markAllAsRead() async {
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
    _unreadCount = 0;
    notifyListeners();
    try {
      await repository.markAllAsRead();
    } catch (e) {}
  }

  Future<void> deleteAll() async {
    final toDelete = List<NotificationModel>.from(_notifications);
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
    try {
      for (final notif in toDelete) {
        await repository.delete(notif.id);
      }
    } catch (e) {}
  }

  Future<void> markAsRead(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].read) {
      _notifications[index] = NotificationModel(
        id: _notifications[index].id,
        title: _notifications[index].title,
        message: _notifications[index].message,
        read: true,
        createdAt: _notifications[index].createdAt,
        type: _notifications[index].type,
      );
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      notifyListeners();
      try {
        await repository.markAsRead(id);
      } catch (e) {}
    }
  }

  Future<void> delete(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final wasUnread = !_notifications[index].read;
      _notifications.removeAt(index);
      if (wasUnread && _unreadCount > 0) _unreadCount--;
      notifyListeners();
      try {
        await repository.delete(id);
      } catch (e) {}
    }
  }
} 