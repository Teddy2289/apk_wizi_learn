import 'package:flutter_test/flutter_test.dart';
import 'package:wizi_learn/features/auth/data/models/formation_model.dart';

void main() {
  group('Formation Model Parsing', () {
    test('Formation.fromJson parses optimized API response correctly', () {
      // This is a sample of the optimized JSON structure from the backend
      final json = {
        'id': 1,
        'titre': 'Test Formation',
        'description': 'A short description...',
        'image_url': 'http://example.com/image.png',
        'duree': '10',
        'statut': 1,
        'categorie': 'Tech',
        // Nested formation category
        'formation': {
          'id': 10,
          'titre': 'Inner Formation',
          'categorie': 'Tech Category',
        },
      };

      final formation = Formation.fromJson(json);

      expect(formation.id, 1);
      expect(formation.titre, 'Test Formation');
      expect(formation.description, 'A short description...');
      expect(formation.imageUrl, 'http://example.com/image.png');
      expect(formation.duree, '10');
      expect(formation.statut, 1);
    });

    test('Formation handles truncated description gracefully', () {
      // Simulates the backend truncating description to 250 chars
      final longDescription = 'A' * 250 + '...';
      final json = {
        'id': 2,
        'titre': 'Truncated Desc Formation',
        'description': longDescription,
        'statut': 1,
      };

      final formation = Formation.fromJson(json);

      expect(formation.description.length, greaterThanOrEqualTo(250));
    });

    test('Formation handles null optional fields with defaults', () {
      final json = {
        'id': 3,
        'titre': 'Minimal Formation',
        'statut': 1,
        // No description, imageUrl, etc.
      };

      final formation = Formation.fromJson(json);

      expect(formation.id, 3);
      expect(formation.titre, 'Minimal Formation');
      // Model uses fallback 'Description non disponible' when null
      expect(formation.description, 'Description non disponible');
      expect(formation.imageUrl, isNull);
    });
  });

  group('FormationCategory Parsing', () {
    test('FormationCategory.fromJson parses correctly', () {
      final json = {
        'id': 5,
        'titre': 'Category Title',
        'categorie': 'Main Category',
      };

      final category = FormationCategory.fromJson(json);

      expect(category.id, 5);
      expect(category.titre, 'Category Title');
      expect(category.categorie, 'Main Category');
    });
  });
}
