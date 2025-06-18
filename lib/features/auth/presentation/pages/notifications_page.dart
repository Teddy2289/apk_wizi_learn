import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            child: const Text('Tout marquer comme lu'),
            onPressed: () {
              // TODO: Marquer toutes les notifs comme lues
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.notifications),
              ),
              title: Text('Notification ${index + 1}'),
              subtitle: const Text('Contenu de la notification...'),
              trailing: const Text('12:30'),
              onTap: () {
                // TODO: Gérer le clic sur une notification
              },
            ),
          );
        },
      ),
    );
  }
}