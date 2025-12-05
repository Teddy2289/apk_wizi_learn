# Fix Flutter Period Filters - Code à Copier-Coller

## 1. Modifier `lib/features/auth/data/repositories/stats_repository.dart`

**Ligne 20 - Remplacer:**

```dart
Future<List<GlobalRanking>> getGlobalRanking() async {
```

**Par:**

```dart
Future<List<GlobalRanking>> getGlobalRanking({String period = 'all'}) async {
```

**Ligne 21 - Remplacer:**

```dart
final response = await apiClient.get(AppConstants.globalRanking);
```

**Par:**

```dart
final response = await apiClient.get('${AppConstants.globalRanking}?period=$period');
```

---

## 2. Modifier  `lib/features/auth/presentation/pages/ranking_page.dart`

**Ligne 14-15 - Ajouter après les imports:**

```dart
import 'package:wizi_learn/features/auth/presentation/widgets/period_filter_chips.dart';
```

**Ligne 33 - Ajouter après `String? _errorMessage;`:**

```dart
String _selectedPeriod = 'all';
```

**Ligne 423-448 - Remplacer toute la méthode `_buildRankingTab`:**

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
            _loadAllData();
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

---

## Test

Après ces modifications:

1. Hot reload Flutter
2. Aller  sur Classement
3. Les 3 boutons filtres devraient apparaître
4. Cliquer pour tester!
