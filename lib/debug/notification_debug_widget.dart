import 'package:flutter/material.dart';
import 'package:wizi_learn/core/services/notification_manager.dart';
import 'package:wizi_learn/features/auth/data/models/notification_model.dart';

class NotificationDebugWidget extends StatelessWidget {
  const NotificationDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final nm = NotificationManager();

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Debug notifications',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    final testNotification = NotificationModel(
                      id: DateTime.now().millisecondsSinceEpoch,
                      title: 'Debug',
                      message: 'Notification de debug',
                      read: false,
                      createdAt: DateTime.now(),
                      type: 'debug',
                    );
                    nm.simulateIncomingNotification(testNotification);
                  },
                  child: const Text('Simuler notif'),
                ),
                ElevatedButton(
                  onPressed: () => nm.incrementUnread(),
                  child: const Text('+1 badge'),
                ),
                ElevatedButton(
                  onPressed: () => nm.decrementUnread(),
                  child: const Text('-1 badge'),
                ),
                ElevatedButton(
                  onPressed: () => nm.setUnreadCount(0),
                  child: const Text('Réinitialiser'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
