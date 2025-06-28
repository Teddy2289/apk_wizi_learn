import 'package:flutter/material.dart';
import 'package:wizi_learn/core/services/notification_manager.dart';

class NotificationBadge extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? badgeColor;
  final Color? textColor;

  const NotificationBadge({
    super.key,
    required this.child,
    this.onTap,
    this.badgeColor,
    this.textColor,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final NotificationManager _notificationManager = NotificationManager();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _unreadCount = _notificationManager.unreadCount;
    _notificationManager.onUnreadCountChanged = _onUnreadCountChanged;
  }

  void _onUnreadCountChanged(int count) {
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          widget.child,
          if (_unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: widget.badgeColor ?? Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                  style: TextStyle(
                    color: widget.textColor ?? Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 