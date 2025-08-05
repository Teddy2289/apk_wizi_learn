import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/notification_badge.dart';

class NotificationIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final double? iconSize;
  final Color? iconColor;
  final Color? badgeColor;
  final Color? badgeTextColor;

  const NotificationIconButton({
    super.key,
    this.onPressed,
    this.icon = Icons.notifications,
    this.iconSize,
    this.iconColor,
    this.badgeColor,
    this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      onTap: onPressed,
      badgeColor: badgeColor,
      textColor: badgeTextColor,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: iconSize,
          color: iconColor,
        ),
        tooltip: 'Notifications',
      ),
    );
  }
} 