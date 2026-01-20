# 🧪 Dashboard Formateur - Checklist de tests

## 📋 Tests fonctionnels

### 1. Chargement initial
- [ ] Page charge correctement
- [ ] Loading spinner s'affiche initialement
- [ ] Données se chargent après 1-2 secondes
- [ ] Pas d'erreur dans les logs

```dart
// Vérifier avec:
flutter logs
// Chercher: Erreur chargement données, Exception, etc
```

### 2. Section Alertes Critiques
- [ ] Affichée si _inactiveStagiaires.length > 0
- [ ] Badge "X Active" correct
- [ ] Avatar + initiales correct
- [ ] Nom du stagiaire correct
- [ ] Message "Last seen" ou "Jamais connecté"
- [ ] Bouton "Follow Up Now" clickable
- [ ] Navigation vers profil stagiaire fonctionne

```
TEST: Appuyer sur "Follow Up Now"
RÉSULTAT: Navigation vers StagiaireProfilePage
```

### 3. Grille de statistiques
- [ ] 4 cartes affichées
- [ ] Icônes corrects
- [ ] Valeurs correctes (total, actifs, score, inactifs)
- [ ] Couleurs correctes (bleu, vert, orange, rouge)
- [ ] Responsive sur petit écran

### 4. Boutons Actions Rapides
- [ ] 3 boutons visibles (Classement, Annonces, Analytics)
- [ ] Clics naviguent vers bonnes pages
- [ ] Design uniforme et aligné

```
TEST NAVIGATION:
- [Classement] → /formateur/classement
- [Annonces] → /formateur/send-notification
- [Analytics] → /formateur/analytics
```

### 5. Filtres et Recherche
- [ ] Barre de recherche visible
- [ ] Focus keyboard fonctionne
- [ ] Texte s'efface/restaure correctement
- [ ] Chips de filtre affichés (All, Active, Formation)
- [ ] Chips se selectionent/deselectionnent

```
TEST FILTRE:
① Cliquer [All Trainees] → affiche tous
② Cliquer [Active] → filtre les actifs uniquement
③ Cliquer [Formation] → affiche les en formation
```

### 6. Recherche en temps réel
- [ ] Typing met à jour la liste
- [ ] Recherche par nom fonctionne
- [ ] Recherche par email fonctionne
- [ ] Case-insensitive
- [ ] Montre "Aucun stagiaire trouvé" si aucun match

```dart
// TEST:
Taper "alex" → ALEX RIVERA apparaît
Taper "chen" → SARAH CHEN apparaît
Taper "xyz" → "Aucun stagiaire trouvé"
```

### 7. Liste Progression Stagiaires
- [ ] Affiche tous les stagiaires (ou filtrés)
- [ ] Avatar avec initiales correctes
- [ ] Nom uppercase
- [ ] Formation name affichée
- [ ] Score moyen correct (%)
- [ ] Nombre de modules correct
- [ ] Jauge circulaire affichée
- [ ] Progression (%) correcte sur jauge

### 8. Couleurs par statut
- [ ] Avatar vert si actif
- [ ] Avatar orange si inactif
- [ ] Avatar rouge si jamais connecté
- [ ] Couleur jauge adaptée (rouge < 25%, orange 25-50%, bleu 50-75%, vert 75%+)

### 9. Pull-to-refresh
- [ ] Swipe down pour refresh
- [ ] Loading spinner s'affiche
- [ ] Données se rechargent
- [ ] Spinner disparaît après chargement

### 10. Gestion des erreurs
- [ ] Erreur API → affiche page vide
- [ ] Timeout → affiche erreur
- [ ] Pas de crash

```dart
// Simuler erreur:
// Dans _apiClient.get() → throw Exception()
```

### 11. Navigation vers profil stagiaire
- [ ] Cliquer sur card de stagiaire → profil
- [ ] Cliquer "Follow Up Now" → profil
- [ ] ID stagiaire correct passé
- [ ] Retour arrière fonctionne

---

## 🎨 Tests UI/UX

### 1. Thème sombre
- [ ] Background #1A1A1A (très sombre)
- [ ] Cards #2A2A2A (gris foncé)
- [ ] Aucun blanc/gris clair
- [ ] Texte blanc sur fond sombre = bon contraste

### 2. Responsive Design
```
TEST SUR ÉCRANS:
- [ ] 360px (petit téléphone)
- [ ] 411px (téléphone standard)
- [ ] 600px (grand téléphone)
- [ ] 800px (tablette)
- [ ] 1200px (grande tablette)

VÉRIFIER:
- [ ] Rien ne déborde
- [ ] Texte lisible
- [ ] Boutons clickables
- [ ] Images adaptées
```

### 3. Orientation
- [ ] Portrait mode : OK
- [ ] Landscape mode : OK
- [ ] Rotation dynamique : OK

### 4. Contraste & Accessibilité
- [ ] Tous les textes ont contraste > 4.5:1
- [ ] Icônes + texte (pas icônes seuls)
- [ ] Tailles minimales 12px pour corps de texte

### 5. Espacements
- [ ] Padding uniforme 12-16px
- [ ] Gaps réguliers entre sections
- [ ] Bottombars a la bonne hauteur

---

## ⚡ Tests Performance

### 1. Chargement
```dart
// Mesurer:
Stopwatch sw = Stopwatch()..start();
await _loadData();
sw.stop();
print('Chargement: ${sw.elapsedMilliseconds}ms');

// CIBLE: < 2000ms
```

### 2. Scroll performance
- [ ] Scroll smooth (60fps)
- [ ] Pas de jank visible
- [ ] Pas de lag lors du scroll

```dart
// DevTools → Performance tab
// Vérifier: 60fps frame rate
```

### 3. Filtrage performance
- [ ] Filtre appliqué instantanément
- [ ] < 100ms pour 1000 stagiaires

### 4. Recherche performance
- [ ] Typing fluide
- [ ] Résultats actualisés < 50ms

### 5. Mémoire
- [ ] Pas de memory leak
- [ ] Memory stable après refresh
- [ ] < 50MB au total (avec images)

```dart
// DevTools → Memory tab
// Snapshot before/after
```

---

## 📱 Tests sur appareils réels

### Téléphones
- [ ] iPhone 12 mini
- [ ] iPhone 12 Pro Max
- [ ] Samsung Galaxy A50
- [ ] Samsung Galaxy S21
- [ ] Google Pixel 5

### Tablettes
- [ ] iPad Air
- [ ] Samsung Galaxy Tab S7

### OS
- [ ] iOS 14+
- [ ] Android 8+

---

## 🌐 Tests API

### 1. Mock data
```dart
// Si API pas disponible, utiliser mock:
const _mockStats = {
  'total_stagiaires': 18,
  'active_this_week': 7,
  'avg_quiz_score': 82,
  'inactive_count': 3,
};
```

### 2. Endpoints réels
```
TEST CHAQUE ENDPOINT:

GET /formateur/dashboard/stats
  Expected: 200 OK
  Fields: total_stagiaires, active_this_week, avg_quiz_score, inactive_count

GET /formateur/stagiaires/inactive?days=7
  Expected: 200 OK
  Fields: inactive_stagiaires[]

GET /formateur/stagiaires/progress
  Expected: 200 OK
  Fields: stagiaires[]

GET /formateur/trends
  Expected: 200 OK
  Fields: quiz_trends[]
```

### 3. Timeout handling
```dart
// Si API lent (> 5s)
- [ ] Affiche erreur gracieusement
- [ ] Pas de freeze
- [ ] User peut retry
```

---

## 🔒 Tests Sécurité

- [ ] Token JWT validé
- [ ] Pas de données sensibles en plaintext
- [ ] Pas de credentials dans logs
- [ ] API token pas exposé en UI
- [ ] HTTPS obligatoire en production

---

## 🐛 Regression Tests

Après chaque modification, vérifier:

- [ ] Ancien Dashboard page still works
- [ ] Navigation ne break pas
- [ ] Autres features pas affectées

---

## ✅ Sign-off Checklist

### QA Lead
- [ ] Tests fonctionnels passent
- [ ] Tests UI/UX validés
- [ ] Performance acceptable
- [ ] Pas de bugs critiques

### Product Owner
- [ ] Design conforme à spec
- [ ] Fonctionnalités complètes
- [ ] UX intuitive
- [ ] Prêt pour release

### DevOps
- [ ] Build APK/AAB réussi
- [ ] Pas de warnings/errors
- [ ] Certifications OK

---

## 📊 Test Report Template

```
DASHBOARD FORMATEUR - TEST REPORT
=====================================

Date: 20/01/2026
Tester: [Name]
Device: [Device/Emulator]
OS: [iOS/Android] [Version]
App Version: 1.0.0

RÉSULTATS:
- Tests fonctionnels: ✅ [X/X] PASS
- Tests UI/UX: ✅ [X/X] PASS
- Tests Performance: ✅ [X/X] PASS
- Tests API: ✅ [X/X] PASS

BUGS TROUVÉS:
1. [Description]
   Severity: [Critical/High/Medium/Low]
   Reproduced: [Yes/No]

RECOMMENDATION:
✅ READY FOR PRODUCTION
❌ NEEDS FIXES (list)
⚠️ CONDITIONAL (list conditions)

Signature: ___________
```

---

## 🎯 Success Criteria

Dashboard est READY si:

```
✅ Tous les tests fonctionnels passent
✅ 0 crashes détectés
✅ 0 memory leaks
✅ Responsive sur tous les appareils
✅ Performance > 60fps
✅ API integration OK
✅ UX flow intuitive
✅ Documentation complète
✅ Code coverage > 80%
✅ Zéro bugs critiques
```

---

## 📝 Notes

- Utiliser émulateur Android 8+ et iOS 14+ minimum
- Tester avec vrais données API quand possible
- Documenter tous les bugs trouvés
- Screenshots pour reproduction

---

**Bon testing! 🧪** 🚀
