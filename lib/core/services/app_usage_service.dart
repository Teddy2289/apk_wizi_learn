import 'dart:async';
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wizi_learn/core/network/api_client.dart';

class AppUsageService {
  AppUsageService._();
  static final AppUsageService instance = AppUsageService._();

  DateTime? _lastReportAt;
  static const Duration _minInterval = Duration(hours: 2);

  Future<void> reportUsage(ApiClient apiClient, {bool force = false}) async {
    if (!force && _lastReportAt != null) {
      final since = DateTime.now().difference(_lastReportAt!);
      if (since < _minInterval) return;
    }

    final String platform = Platform.isAndroid ? 'android' : 'ios';

    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();

    String appVersion = packageInfo.version;
    String deviceModel = '';
    String osVersion = '';

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      final manufacturer = info.manufacturer?.trim() ?? '';
      final model = info.model?.trim() ?? '';
      deviceModel = (manufacturer + ' ' + model).trim();
      osVersion = info.version.release ?? '';
    } else {
      final info = await deviceInfo.iosInfo;
      deviceModel = info.utsname.machine ?? '';
      osVersion = info.systemVersion ?? '';
    }

    try {
      await apiClient.post(
        '/api/user-app-usage',
        data: {
          'platform': platform,
          'app_version': appVersion,
          'device_model': deviceModel,
          'os_version': osVersion,
        },
      );
      _lastReportAt = DateTime.now();
    } catch (_) {
      // Ignorer silencieusement. Gestion d'erreur réseau/401 ailleurs si besoin.
    }
  }
}
