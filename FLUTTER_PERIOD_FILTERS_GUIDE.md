# Flutter Classement - Filtres de Période

## Modifications Nécessaires

### 1. Fichier: ranking_page.dart

**Ajouter l'import:**

```dart
import 'package:wizi_learn/features/auth/presentation/widgets/period_filter_chips.dart';
```

**Ajouter la variable d'état (ligne ~33):**

```dart
String _selectedPeriod = 'all'; // Add period filter state
```

**Modifier _loadAllData (ligne ~70):**

```dart
_rankingFuture = _repository.getGlobalRanking(period: _selectedPeriod);
```

**Remplacer _buildRankingTab (ligne ~423):**

```dart
Widget _buildRankingTab(bool isLandscape) {
  return Padding(
    padding: EdgeInsets.all(isLandscape ? 8 : 16),
    child: Column(
      children: [
        // Period filter chips
        PeriodFilterChips(
          selectedPeriod: _selectedPeriod,
          onPeriodChanged: (period) {
            setState(() {
              _selectedPeriod = period;
            });
            _loadAllData(); // Reload data with new period
          },
        ),
        const SizedBox(height: 16),
        // Ranking content
        Expanded(
          child: FutureBuilder<List<GlobalRanking>>(
            future: _rankingFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(
                  child: Text('Erreur de chargement du classement'),
                );
              }
              return Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isLandscape ? 12 : 16),
                ),
                child: GlobalRankingWidget(rankings: snapshot.data!),
              );
            },
          ),
        ),
      ],
    ),
  );
}
```

### 2. Fichier: stats_repository.dart

**Modifier getGlobalRanking:**

```dart
Future<List<GlobalRanking>> getGlobalRanking({String period = 'all'}) async {
  final response = await _apiClient.get(
    '/quiz/classement/global',
    queryParameters: {'period': period}, // Add period parameter  
  );
  
  if (response.statusCode == 200) {
    final data = response.data as List;
    return data.map((json) => GlobalRanking.fromJson(json)).toList();
  }
  throw Exception('Failed to load global ranking');
}
```

### 3. Fichier Créé: period_filter_chips.dart ✅

Le widget PeriodFilterChips a déjà été créé dans:
`lib/features/auth/presentation/widgets/period_filter_chips.dart`

## Test

1. Ouvrir l'app Flutter
2. Aller sur la page Classement
3. Voir les 3 boutons de filtre en haut
4. Cliquer sur chaque bouton
5. Le classement devrait se recharger avec les données filtrées
