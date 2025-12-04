import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/presentation/pages/contact_faq_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/dashboard_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/detail_formation_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/faq_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/formation_stagiaire_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/my_progression.dart';
import 'package:wizi_learn/features/auth/presentation/pages/notifications_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/privacy_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/ranking_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/sponsor_ship_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/terms_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/thanks_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/training_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/user_manual_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/user_point_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/quiz_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/quiz_adventure_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/media_tutorial_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/challenge_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/achievement_page.dart';
import '../constants/route_constants.dart';
import '../../features/auth/presentation/pages/auth/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import 'package:wizi_learn/features/auth/presentation/pages/contact_page.dart';
import 'package:wizi_learn/features/commercial/screens/commercial_dashboard_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteConstants.achievement:
        return MaterialPageRoute(builder: (_) => const AchievementPage());
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
        return MaterialPageRoute(
          builder: (_) => const QuizPage(quizAdventureEnabled: false),
        );

      case RouteConstants.quizAdventure:
        return MaterialPageRoute(builder: (_) => const QuizAdventurePage());

      case RouteConstants.tutorialPage:
        return MaterialPageRoute(builder: (_) => const MediaTutorialPage());

      case RouteConstants.challenge:
        return MaterialPageRoute(builder: (_) => const ChallengePage());

      case RouteConstants.formations:
        return MaterialPageRoute(
          builder: (_) => const FormationStagiairePage(),
        );
      case RouteConstants.faq:
        return MaterialPageRoute(builder: (_) => const FAQPage());

      case RouteConstants.contact:
        return MaterialPageRoute(builder: (_) => const ContactFaqPage());
      case RouteConstants.mescontact:
        return MaterialPageRoute(
          builder: (_) => const ContactPage(contacts: []),
        );
      case RouteConstants.terms:
        return MaterialPageRoute(builder: (_) => const TermsPage());

      case RouteConstants.userManual:
        return MaterialPageRoute(builder: (_) => const UserManualPage());

      case RouteConstants.thanks:
        return MaterialPageRoute(builder: (_) => const ThanksPage());

      case RouteConstants.privacy:
        return MaterialPageRoute(builder: (_) => const PrivacyPage());
      
      case RouteConstants.commercialDashboard:
        return MaterialPageRoute(
          builder: (_) => const CommercialDashboardScreen(),
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
