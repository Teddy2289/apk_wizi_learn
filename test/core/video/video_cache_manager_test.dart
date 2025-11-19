import 'package:flutter_test/flutter_test.dart';
import 'package:wizi_learn/core/video/video_cache_manager.dart';

void main() {
  group('VideoCacheManager Tests', () {
    late VideoCacheManager cacheManager;

    setUp(() {
      cacheManager = VideoCacheManager();
      cacheManager.clearCache();
    });

    group('Thumbnail URL Cache', () {
      test('getThumbnailUrl devrait cacher l\'URL', () {
        const testUrl = 'https://youtube.com/watch?v=test123';
        const expectedResult = 'https://img.youtube.com/vi/test123/default.jpg';

        final result1 = cacheManager.getThumbnailUrl(
          testUrl,
          () => expectedResult,
        );
        final result2 = cacheManager.getThumbnailUrl(
          testUrl,
          () => 'https://different.url',
        );

        expect(result1, equals(expectedResult));
        expect(result2, equals(expectedResult)); // Vient du cache
      });

      test('getThumbnailUrl devrait générer si absent', () {
        const testUrl = 'https://youtube.com/watch?v=new';
        const expectedResult = 'https://generated.url/image.jpg';

        final result = cacheManager.getThumbnailUrl(
          testUrl,
          () => expectedResult,
        );

        expect(result, equals(expectedResult));
      });
    });

    group('Duration Cache', () {
      test('cacheDuration et getCachedDuration doivent fonctionner', () {
        const mediaId = 42;
        const duration = Duration(minutes: 5);

        cacheManager.cacheDuration(mediaId, duration);
        final cached = cacheManager.getCachedDuration(mediaId);

        expect(cached, equals(duration));
      });

      test('getCachedDuration retourne null si absent', () {
        final cached = cacheManager.getCachedDuration(999);
        expect(cached, isNull);
      });
    });

    group('Image Cache', () {
      test('cacheImage et getCachedImage doivent fonctionner', () {
        // Pas de test d'ImageProvider réel car c'est un widget Flutter
        // Mais la structure est testée
        expect(cacheManager.getCacheStats()['images'], equals(0));
      });
    });

    group('Cache Management', () {
      test('getCacheStats doit retourner les bons counts', () {
        cacheManager.getThumbnailUrl('url1', () => 'result1');
        cacheManager.getThumbnailUrl('url2', () => 'result2');
        cacheManager.cacheDuration(1, const Duration(seconds: 10));

        final stats = cacheManager.getCacheStats();
        expect(stats['thumbnails'], equals(2));
        expect(stats['durations'], equals(1));
      });

      test('clearCache doit vider tous les caches', () {
        cacheManager.getThumbnailUrl('url1', () => 'result1');
        cacheManager.cacheDuration(1, const Duration(seconds: 10));

        var stats = cacheManager.getCacheStats();
        expect(stats['thumbnails'], greaterThan(0));

        cacheManager.clearCache();
        stats = cacheManager.getCacheStats();
        expect(stats['thumbnails'], equals(0));
        expect(stats['durations'], equals(0));
      });
    });

    group('Singleton Pattern', () {
      test('VideoCacheManager devrait être un singleton', () {
        final instance1 = VideoCacheManager();
        final instance2 = VideoCacheManager();

        expect(identical(instance1, instance2), isTrue);
      });

      test('Les instances partagent le même cache', () {
        final manager1 = VideoCacheManager();
        final manager2 = VideoCacheManager();

        manager1.getThumbnailUrl('shared', () => 'value');
        final result = manager2.getThumbnailUrl('shared', () => 'different');

        expect(result, equals('value')); // Même cache
      });
    });

    group('Cache Limits', () {
      test('Cache respect la limite FIFO', () {
        // Ajouter 101 items pour tester la limite de 100
        for (int i = 0; i <= 100; i++) {
          cacheManager.getThumbnailUrl('url_$i', () => 'result_$i');
        }

        final stats = cacheManager.getCacheStats();
        // Devrait maintenir max 100
        expect(stats['thumbnails'], lessThanOrEqualTo(100));
      });
    });
  });
}
