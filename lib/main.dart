import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wizi_learn/firebase_options.dart';
import 'package:wizi_learn/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wizi_learn/features/auth/presentation/bloc/auth_event.dart';
import 'package:wizi_learn/features/auth/presentation/constants/couleur_palette.dart';
import 'features/auth/auth_injection_container.dart' as auth_injection;
import 'features/auth/data/repositories/auth_repository.dart';
import 'core/services/fcm_service_mobile.dart'
    if (dart.library.html) 'core/services/fcm_service_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:wizi_learn/core/services/notification_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wizi_learn/presentation/onboarding_flow/onboarding_flow.dart';
import 'features/auth/presentation/pages/auth/login_page.dart';
import 'core/routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialiser le gestionnaire de notifications
  await NotificationManager().initialize();

  // Initialize dependencies
  await auth_injection.initAuthDependencies();

  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  runApp(MyApp(onboardingCompleted: onboardingCompleted));
}

class MyApp extends StatelessWidget {
  final bool onboardingCompleted;
  const MyApp({required this.onboardingCompleted, super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FcmService().initFcm(context);
      });
    }
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => auth_injection.sl<AuthRepository>(),
        ),
      ],
      child: BlocProvider<AuthBloc>(
        create:
            (context) =>
                AuthBloc(authRepository: context.read<AuthRepository>())
                  ..add(CheckAuthEvent()),
        child: MaterialApp(
          title: 'Wizi Learn',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme(
              primary: AppColors.primary,
              primaryContainer: AppColors.primaryDark,
              secondary: AppColors.secondary,
              secondaryContainer: AppColors.secondary.withOpacity(0.8),
              surface: AppColors.surface,
              error: AppColors.error,
              onPrimary: AppColors.onPrimary,
              onSecondary: AppColors.onSecondary,
              onSurface: AppColors.onSurface,
              onError: AppColors.onError,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: AppColors.background,
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 4,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.onPrimary,
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey.shade600,
              elevation: 8,
            ),
            cardTheme: CardThemeData(
              color: AppColors.surface,
              elevation: 2,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
            useMaterial3: true, // Pour Material 3
          ),
          scrollBehavior: CustomScrollBehavior(),
          initialRoute: onboardingCompleted ? '/login' : '/onboarding',
          onGenerateRoute: (settings) {
            // Pour l'onboarding et le login, routes directes
            if (settings.name == '/onboarding') {
              return MaterialPageRoute(builder: (_) => const OnboardingFlow());
            }
            if (settings.name == '/login') {
              return MaterialPageRoute(builder: (_) => const LoginPage());
            }
            // Pour toutes les autres routes, utiliser AppRouter
            // (import à ajouter en haut du fichier)
            return AppRouter.generateRoute(settings);
          },
        ),
      ),
    );
  }
}

class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
      color: Colors.orange.shade200,
      child: child,
    );
  }
}
