import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/presentation/pages/dashboard_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/formation_stagiaire_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/my_progression.dart';
import 'package:wizi_learn/features/auth/presentation/pages/notifications_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/ranking_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/sponsor_ship_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/user_point_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/quiz_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/tutorial_page.dart';
import '../constants/route_constants.dart';
import '../../features/auth/presentation/pages/auth/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteConstants.splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());

      case RouteConstants.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case RouteConstants.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());

      // route pour le parrainage
      case RouteConstants.sponsorship:
        return MaterialPageRoute(builder: (_) => const SponsorshipPage());

      // route pour les points utilisateur
      case RouteConstants.userPoints:
        return MaterialPageRoute(builder: (_) => const UserPointsPage());

      // route pour les notifications
      case RouteConstants.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsPage());

      case RouteConstants.classement:
        return MaterialPageRoute(builder: (_) => const RankingPage());
      case RouteConstants.myTrainings:
        return MaterialPageRoute(
          builder: (_) => const FormationStagiairePage(),
        );
      case RouteConstants.myProgress:
        return MaterialPageRoute(builder: (_) => const ProgressPage());

      // Nouvelles routes ajoutées
      case RouteConstants.quiz:
        return MaterialPageRoute(builder: (_) => const QuizPage());

      case RouteConstants.tutorialPage:
        return MaterialPageRoute(builder: (_) => const TutorialPage());

      case RouteConstants.formations:
        return MaterialPageRoute(
          builder: (_) => const FormationStagiairePage(),
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
