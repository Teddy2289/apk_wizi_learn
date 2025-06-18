import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/presentation/pages/dashboard_page.dart';
import '../constants/route_constants.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import 'package:wizi_learn/features/auth/domain/user_entity.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteConstants.splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());

      case RouteConstants.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case RouteConstants.dashboard:
        return MaterialPageRoute(
          builder: (_) => DashboardPage(user: settings.arguments as UserEntity),
        );

      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
