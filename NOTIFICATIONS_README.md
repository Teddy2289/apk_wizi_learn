# Système de Notifications FCM pour Flutter

Ce document explique l'implémentation du système de notifications Firebase Cloud Messaging (FCM) dans l'application Flutter Wizi Learn.

## Architecture

### 1. Services Principaux

#### `FirebaseNotificationService`
- Gère l'initialisation de Firebase Messaging
- Configure les permissions de notifications
- Gère les tokens FCM
- Écoute les messages en premier plan et arrière-plan

#### `NotificationManager`
- Service global pour gérer les notifications
- Maintient l'état des notifications (liste, compteur non lus)
- Fournit des callbacks pour les mises à jour en temps réel
- Gère les notifications locales

#### `NotificationRepository`
- Interface avec l'API backend
- Gère les opérations CRUD sur les notifications
- Intègre FCM avec les notifications du serveur

### 2. Widgets

#### `NotificationBadge`
- Widget réutilisable pour afficher un badge avec compteur
- Se met à jour automatiquement quand de nouvelles notifications arrivent

#### `NotificationIconButton`
- Bouton d'icône avec badge intégré
- Utilise `NotificationBadge` en interne

### 3. Pages

#### `NotificationsPage`
- Page principale pour afficher toutes les notifications
- Gère les interactions (marquer comme lu, supprimer)
- Intègre FCM pour les notifications en temps réel

## Configuration

### 1. Firebase Setup

Le projet utilise les configurations Firebase suivantes :

```dart
// firebase_options.dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyAAAaZVClNlMXgTktyjUg8lhLG5zSue4YY',
  appId: '1:69521612278:web:94878d39de047f667c7bd7',
  messagingSenderId: '69521612278',
  projectId: 'wizi-learn',
  authDomain: 'wizi-learn.firebaseapp.com',
  storageBucket: 'wizi-learn.firebasestorage.app',
  measurementId: 'G-01Y7WC8383',
);
```

### 2. Initialisation

Dans `main.dart` :

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialiser le gestionnaire de notifications
  await NotificationManager().initialize();
  
  runApp(const MyApp());
}
```

## Utilisation

### 1. Ajouter un badge de notifications

```dart
NotificationIconButton(
  onPressed: () => Navigator.pushNamed(context, '/notifications'),
  icon: Icons.notifications,
  badgeColor: Colors.red,
)
```

### 2. Écouter les nouvelles notifications

```dart
final notificationManager = NotificationManager();

// Définir un callback
notificationManager.onNotificationReceived = (notification) {
  // Traiter la nouvelle notification
  print('Nouvelle notification: ${notification.title}');
};

// Écouter les changements de compteur
notificationManager.onUnreadCountChanged = (count) {
  // Mettre à jour l'interface
  setState(() {
    unreadCount = count;
  });
};
```

### 3. Gérer les notifications

```dart
// Marquer comme lu
notificationManager.markAsRead(notificationId);

// Marquer toutes comme lues
notificationManager.markAllAsRead();

// Supprimer une notification
notificationManager.deleteNotification(notificationId);

// Supprimer toutes
notificationManager.deleteAllNotifications();
```

## Intégration avec le Backend

### 1. Envoi de Token FCM

Le token FCM est automatiquement envoyé au backend lors de l'initialisation :

```dart
// Dans FirebaseNotificationService
Future<void> _sendTokenToServer(String token) async {
  try {
    await _apiClient.post('/fcm-token', data: {'token': token});
  } catch (e) {
    print('Erreur lors de l\'envoi du token FCM: $e');
  }
}
```

### 2. Réception des Notifications

Les notifications sont reçues via FCM et stockées localement :

```dart
// Dans FirebaseNotificationService
void _setupForegroundMessageHandler() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Créer une notification locale
    _showLocalNotification(message);
    
    // Créer un modèle de notification
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch,
      title: message.notification?.title ?? 'Notification',
      message: message.notification?.body ?? '',
      read: false,
      createdAt: DateTime.now(),
      type: message.data['type'] ?? 'system',
    );
    
    // Appeler le callback
    if (onNotificationReceived != null) {
      onNotificationReceived!(notification);
    }
  });
}
```

## Types de Notifications

### 1. Quiz
- Type: `'quiz'`
- Navigation: `/quiz`
- Icône: 📝

### 2. Formation
- Type: `'formation'`
- Navigation: `/formations`
- Icône: 📚

### 3. Média
- Type: `'media'`
- Navigation: `/tutoriel`
- Icône: 🎥

### 4. Badge
- Type: `'badge'`
- Navigation: `/badges`
- Icône: 🏆

### 5. Système
- Type: `'system'`
- Pas de navigation automatique
- Icône: 🔔

## Fonctionnalités

### 1. Notifications en Temps Réel
- Réception instantanée via FCM
- Mise à jour automatique de l'interface
- Badges avec compteur en temps réel

### 2. Notifications Locales
- Affichage de notifications système
- Gestion des permissions
- Configuration de canaux Android

### 3. Gestion d'État
- Compteur de notifications non lues
- Liste des notifications
- Synchronisation avec le backend

### 4. Navigation Intelligente
- Redirection automatique selon le type
- Gestion des actions de notification
- Historique de navigation

## Tests

### 1. Notification de Test

Utilisez le bouton de test dans `NotificationsPage` :

```dart
void _sendTestNotification() async {
  try {
    await repository.sendTestNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification de test envoyée')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de l\'envoi: $e')),
    );
  }
}
```

### 2. Test FCM

Route de test disponible dans l'API :

```
GET /test-fcm
```

## Dépendances

```yaml
dependencies:
  firebase_core: ^3.14.0
  firebase_messaging: ^15.2.7
  firebase_core_web: ^2.23.0
  firebase_messaging_web: ^3.10.7
  flutter_local_notifications: ^19.3.0
```

## Notes Importantes

1. **Permissions** : Les notifications nécessitent l'autorisation de l'utilisateur
2. **Tokens** : Les tokens FCM sont automatiquement gérés et envoyés au backend
3. **État** : Le gestionnaire de notifications maintient l'état global
4. **Performance** : Les notifications sont optimisées pour éviter les doublons
5. **Compatibilité** : Support complet pour Android, iOS et Web

## Troubleshooting

### Problèmes Courants

1. **Notifications non reçues**
   - Vérifier les permissions
   - Vérifier la configuration Firebase
   - Vérifier la connexion internet

2. **Badge ne se met pas à jour**
   - Vérifier les callbacks
   - Vérifier l'état du widget

3. **Erreurs FCM**
   - Vérifier la configuration Firebase
   - Vérifier les tokens
   - Vérifier les logs

### Logs Utiles

```dart
// Activer les logs détaillés
print('Token FCM: $token');
print('Notification reçue: ${message.notification?.title}');
print('Compteur non lus: $unreadCount');
``` 

## Synchronisation FCM <-> API

Le projet synchronise les notifications reçues via FCM avec l'état côté serveur :

- Lorsqu'un message FCM arrive en premier plan, `FirebaseNotificationService` crée une notification locale et appelle le callback défini par `NotificationRepository`.
- `NotificationProvider` met à jour immédiatement l'état local (UI réactive) puis planifie une `refresh()` dé-bounceée (2s) pour récupérer l'état canonique depuis l'API.
- Cette stratégie évite les doublons et réduit les appels répétés au backend lorsque plusieurs pushes arrivent en rafale.

Conseil : ajoutez un "pull-to-refresh" sur la page de notifications qui appelle `provider.refresh()` pour forcer une synchronisation manuelle.
