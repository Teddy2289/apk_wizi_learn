# Guide d'Intégration: Accès Hors Ligne - Page Catalogue

## Vue d'Ensemble

Le `CatalogueCacheService` permet de mettre en cache le catalogue de formations pour un accès hors ligne avec une validité de 2 jours.

---

## Intégration dans TrainingPage / CataloguePage

### 1. Importer les Services

```dart
import 'package:wizi_learn/features/catalogue/services/catalogue_cache_service.dart';
import 'package:wizi_learn/core/services/connectivity_service.dart';
import 'package:wizi_learn/core/services/offline_services_init.dart';
import 'package:wizi_learn/core/widgets/connectivity_banner.dart';
```

### 2. Injection des Services

```dart
class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});
  
  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  final CatalogueCacheService _catalogueCache = 
      offlineServiceLocator<CatalogueCacheService>();
  final ConnectivityService _connectivityService = 
      offlineServiceLocator<ConnectivityService>();
  
  List<Formation> _formations = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isFromCache = false;
  
  @override
  void initState() {
    super.initState();
    _loadCatalogue();
  }
```

### 3. Charger les Données avec Fallback Cache

```dart
Future<void> _loadCatalogue() async {
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
    // Charger depuis votre repository existant
    final formations = await _formationRepository.getAllFormations();
    final categories = await _categoryRepository.getCategories();
    
    // Mettre en cache pour usage hors ligne
    await _catalogueCache.cacheAllFormations(
      formations.map((f) => f.toJson()).toList(),
    );
    await _catalogueCache.cacheCategories(
      categories.map((c) => c.toJson()).toList(),
    );
    
    setState(() {
      _formations = formations;
      _categories = categories;
      _isFromCache = false;
    });
  } catch (e) {
    debugPrint('Erreur chargement API: $e');
    // En cas d'erreur, essayer le cache
    await _loadFromCache();
  }
}

Future<void> _loadFromCache() async {
  final cachedFormations = _catalogueCache.getCachedAllFormations();
  final cachedCategories = _catalogueCache.getCachedCategories();
  
  if (cachedFormations != null && cachedCategories != null) {
    setState(() {
      _formations = cachedFormations
          .map((json) => Formation.fromJson(json))
          .toList();
      _categories = cachedCategories
          .map((json) => Category.fromJson(json))
          .toList();
      _isFromCache = true;
    });
  } else {
    // Pas de cache disponible
    setState(() {
      _formations = [];
      _categories = [];
      _isFromCache = false;
    });
  }
}
```

### 4. Filtrage par Catégorie avec Cache

```dart
Future<void> _loadFormationsByCategory(String categoryId) async {
  final isOnline = await _connectivityService.isConnected;
  
  if (isOnline) {
    try {
      final formations = await _formationRepository
          .getFormationsByCategory(categoryId);
      
      // Mettre en cache cette catégorie
      await _catalogueCache.cacheFormationsByCategory(
        categoryId,
        formations.map((f) => f.toJson()).toList(),
      );
      
      setState(() {
        _formations = formations;
        _isFromCache = false;
      });
    } catch (e) {
      _loadCategoryFromCache(categoryId);
    }
  } else {
    _loadCategoryFromCache(categoryId);
  }
}

void _loadCategoryFromCache(String categoryId) {
  final cached = _catalogueCache.getCachedFormationsByCategory(categoryId);
  
  if (cached != null) {
    setState(() {
      _formations = cached
          .map((json) => Formation.fromJson(json))
          .toList();
      _isFromCache = true;
    });
  }
}
```

### 5. UI avec ConnectivityBanner

```dart
@override
Widget build(BuildContext context) {
  return ConnectivityBanner(
    connectivityService: _connectivityService,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue'),
        actions: [
          if (_isFromCache)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                avatar: Icon(Icons.cached, size: 16),
                label: Text('Cache'),
                backgroundColor: Colors.orange.shade100,
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFromApi,
        child: _buildContent(),
      ),
    ),
  );
}

Widget _buildContent() {
  if (_isLoading) {
    return Center(child: CircularProgressIndicator());
  }
  
  if (_formations.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            _isFromCache
                ? 'Aucune formation en cache'
                : 'Aucune formation disponible',
          ),
          SizedBox(height: 16),
          if (!_isFromCache)
            ElevatedButton.icon(
              onPressed: _loadCatalogue,
              icon: Icon(Icons.refresh),
              label: Text('Réessayer'),
            ),
        ],
      ),
    );
  }
  
  return ListView.builder(
    itemCount: _formations.length,
    itemBuilder: (context, index) {
      return _buildFormationCard(_formations[index]);
    },
  );
}
```

### 6. Indicateur de Cache

Afficher la date de dernière mise en cache :

```dart
Widget _buildCacheInfo() {
  final lastCacheDate = _catalogueCache.getLastCacheDate();
  
  if (lastCacheDate == null || !_isFromCache) {
    return SizedBox.shrink();
  }
  
  final timeAgo = DateTime.now().difference(lastCacheDate);
  String timeText;
  
  if (timeAgo.inHours < 1) {
    timeText = '${timeAgo.inMinutes} min';
  } else if (timeAgo.inDays < 1) {
    timeText = '${timeAgo.inHours}h';
  } else {
    timeText = '${timeAgo.inDays}j';
  }
  
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 16, color: Colors.blue.shade700),
          SizedBox(width: 4),
          Text(
            'Mis en cache il y a $timeText',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade900,
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

## Synchronisation Automatique

```dart
StreamSubscription? _connectivitySubscription;

@override
void initState() {
  super.initState();
  _loadCatalogue();
  
  // Synchroniser au retour en ligne
  _connectivitySubscription = _connectivityService
      .onConnectivityChanged
      .listen((isOnline) {
    if (isOnline && _isFromCache) {
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

---

## Gestion du Rafraîchissement

```dart
// Pull-to-refresh force le chargement depuis l'API
Future<void> _handleRefresh() async {
  final isOnline = await _connectivityService.isConnected;
  
  if (isOnline) {
    await _loadFromApi();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Impossible de rafraîchir hors ligne'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
```

---

## Bénéfices

✅ **Consultation immédiate** du catalogue même hors ligne  
✅ **Recherche et filtrage** fonctionnent sur les données en cache  
✅ **Cache de 2 jours** évite les chargements répétés  
✅ **Synchronisation auto** au retour en ligne  
✅ **Expérience fluide** sur connexions instables

---

## Notes

- Cache valide pendant **2 jours**
- Cache global + cache par catégorie
- Pull-to-refresh force l'actualisation
- Indicateur visuel du mode cache
- Fallback automatique en cas d'erreur réseau
