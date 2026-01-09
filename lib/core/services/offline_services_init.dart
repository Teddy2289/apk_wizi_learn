import 'package:get_it/get_it.dart';
import 'package:wizi_learn/core/services/cache_service.dart';
import 'package:wizi_learn/core/services/connectivity_service.dart';
import 'package:wizi_learn/features/auth/services/user_data_cache_service.dart';
import 'package:wizi_learn/features/media/services/video_download_service.dart';
import 'package:wizi_learn/features/media/models/offline_video.dart';
import 'package:wizi_learn/features/catalogue/services/catalogue_cache_service.dart';
import 'package:dio/dio.dart';

/// Service locator global pour l'accès hors ligne
final offlineServiceLocator = GetIt.instance;

/// Initialise tous les services liés à l'accès hors ligne
Future<void> initOfflineServices() async {
  // Cache Service
  final cacheService = CacheService();
  await cacheService.init();
  offlineServiceLocator.registerSingleton<CacheService>(cacheService);

  // Connectivity Service
  final connectivityService = ConnectivityService();
  offlineServiceLocator.registerSingleton<ConnectivityService>(connectivityService);

  // User Data Cache Service
  final userDataCacheService = UserDataCacheService(cacheService);
  offlineServiceLocator.registerSingleton<UserDataCacheService>(userDataCacheService);

  // Catalogue Cache Service
  final catalogueCacheService = CatalogueCacheService(cacheService);
  offlineServiceLocator.registerSingleton<CatalogueCacheService>(catalogueCacheService);

  // Video Download Service
  final dio = Dio();
  final videoDownloadService = VideoDownloadService(dio);
  offlineServiceLocator.registerSingleton<VideoDownloadService>(videoDownloadService);

  // Offline Storage Manager
  final offlineStorageManager = OfflineStorageManager(cacheService);
  offlineServiceLocator.registerSingleton<OfflineStorageManager>(offlineStorageManager);
}
