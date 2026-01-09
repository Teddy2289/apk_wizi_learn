# Guide d'Intégration: Accès Hors Ligne - Page de Profil

## Modifications Nécessaires

### 1. Initialisation des Services (main.dart)

```dart
import 'package:wizi_learn/core/services/offline_services_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser les services hors ligne
  await initOfflineServices();
  
  runApp(MyApp());
}
```

### 2. Wrapper avec ConnectivityBanner

Envelopper la page de profil avec le `ConnectivityBanner`:

```dart
import 'package:wizi_learn/core/widgets/connectivity_banner.dart';
import 'package:wizi_learn/core/services/offline_services_init.dart';

@override
Widget build(BuildContext context) {
  return ConnectivityBanner(
    connectivityService: offlineServiceLocator<ConnectivityService>(),
    child: Scaffold(
      appBar: AppBar(title: Text('Mon Profil')),
      body: _buildProfileContent(),
    ),
  );
}
```

### 3. Charger les Données avec Fallback Cache

Exemple d'implémentation dans votre page de profil:

```dart
import 'package:wizi_learn/features/auth/services/user_data_cache_service.dart';
import 'package:wizi_learn/core/services/connectivity_service.dart';

class ProfilePage extends StatefulWidget {
  // ...
}

class _ProfilePageState extends State<ProfilePage> {
  final UserDataCacheService _cacheService = 
      offlineServiceLocator<UserDataCacheService>();
  final ConnectivityService _connectivityService = 
      offlineServiceLocator<ConnectivityService>();
  
  User? _user;
  Map<String, dynamic>? _stats;
  List<dynamic>? _badges;
  bool _isLoading = true;
  bool _isFromCache = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    // Vérifier la connectivité
    final isOnline = await _connectivityService.isConnected;
    
    if (isOnline) {
      // Mode en ligne: charger depuis l'API
      await _loadFromApi();
    } else {
      // Mode hors ligne: charger depuis le cache
      await _loadFromCache();
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadFromApi() async {
    try {
      // Charger depuis votre API existante
      final user = await _authRepository.getMe();
      final stats = await _statsRepository.getUserStats();
      final badges = await _badgeRepository.getUserBadges();
      
      // Mettre en cache pour usage hors ligne
      await _cacheService.cacheUserProfile(user);
      await _cacheService.cacheUserStats(stats);
      await _cacheService.cacheUserBadges(badges);
      
      setState(() {
        _user = user;
        _stats = stats;
        _badges = badges;
        _isFromCache = false;
      });
    } catch (e) {
      // En cas d'erreur réseau, essayer le cache
      await _loadFromCache();
    }
  }

  Future<void> _loadFromCache() async {
    final cachedUser = _cacheService.getCachedUserProfile();
    final cachedStats = _cacheService.getCachedUserStats();
    final cachedBadges = _cacheService.getCachedUserBadges();
    
    setState(() {
      _user = cachedUser;
      _stats = cachedStats;
      _badges = cachedBadges;
      _isFromCache = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Impossible de charger les données'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadUserData,
              child: Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadFromApi,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Indicateur de cache optionnel
          if (_isFromCache)
            Container(
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Données en cache (hors ligne)',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
          
          // Afficher les informations du profil
          _buildProfileCard(_user!),
          SizedBox(height: 16),
          
          // Afficher les statistiques
          if (_stats != null) _buildStatsCard(_stats!),
          SizedBox(height: 16),
          
          // Afficher les badges
          if (_badges != null) _buildBadgesSection(_badges!),
        ],
      ),
    );
  }
  
  Widget _buildProfileCard(User user) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Icon(Icons.person, size: 50)
                  : null,
            ),
            SizedBox(height: 16),
            Text(
              user.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
  
  // ... reste des widgets
}
```

### 4. Gestion du Cache Expiré

Pour afficher un message si le cache est trop ancien:

```dart
void _checkCacheValidity() {
  if (_isFromCache) {
    final isValid = _cacheService.isCacheValid(
      'cached_user_profile',
      Duration(days: 7),
    );
    
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Les données en cache sont anciennes'),
          action: SnackBarAction(
            label: 'Actualiser',
            onPressed: _loadFromApi,
          ),
        ),
      );
    }
  }
}
```

### 5. Synchronisation au Retour en Ligne

Écouter les changements de connectivité:

```dart
StreamSubscription? _connectivitySubscription;

@override
void initState() {
  super.initState();
  _loadUserData();
  
  // Écouter les changements de connectivité
  _connectivitySubscription = _connectivityService
      .onConnectivityChanged
      .listen((isOnline) {
    if (isOnline && _isFromCache) {
      // Retour en ligne: rafraîchir les données
      _loadFromApi();
    }
  });
}

@override
void dispose() {
  _connectivitySubscription?.cancel();
  super.dispose();
}
```

## Bénéfices

✅ **Accès instantané** aux informations même hors ligne
✅ **Expérience utilisateur améliorée** sur connexions instables
✅ **Synchronisation automatique** au retour en ligne
✅ **Gestion du cache** avec expiration automatique

## Notes Importantes

- Le cache est valide 7 jours pour le profil
- Les stats sont valides 1 jour
- Les badges sont valides 7 jours
- Pull-to-refresh force une actualisation depuis l'API
