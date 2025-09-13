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
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:wizi_learn/core/services/notification_manager.dart';
import 'package:wizi_learn/features/auth/presentation/pages/splash_page.dart';
import 'core/routes/app_router.dart';
import 'package:provider/provider.dart';
import 'features/auth/presentation/providers/notification_provider.dart';
import 'features/auth/data/repositories/notification_repository.dart';
import 'core/network/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    // Ignore duplicate-app error on hot restart
    if (e.toString().contains('core/duplicate-app')) {
      // Already initialized, safe to continue
    } else {
      rethrow;
    }
  }

  // Initialiser le gestionnaire de notifications
  await NotificationManager().initialize();

  // Initialiser les dépendances
  await auth_injection.initAuthDependencies();
  const String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://wizi-learn.com',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialiser FCM sur mobile
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FcmService().initFcm(context);
      });
    }
    // Fournir NotificationProvider à toute l'app
    return ChangeNotifierProvider(
      create: (_) {
        final apiClient = ApiClient(
          dio: Dio(),
          storage: const FlutterSecureStorage(),
        );
        final notifRepo = NotificationRepository(apiClient: apiClient);
        final provider = NotificationProvider(repository: notifRepo);
        provider.initialize();
        return provider;
      },
      child: MultiRepositoryProvider(
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
              fontFamily: "Montserrat",
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
              useMaterial3: true,
            ),
            // Reduce iOS font scaling by overriding MediaQuery.textScaleFactor
            builder: (context, child) {
              if (defaultTargetPlatform == TargetPlatform.iOS) {
                final mq = MediaQuery.of(context);
                // Adjust this factor to taste (0.9 reduces fonts to 90%)
                return MediaQuery(
                  data: mq.copyWith(textScaleFactor: 0.9),
                  child: child ?? const SizedBox.shrink(),
                );
              }
              return child ?? const SizedBox.shrink();
            },
            scrollBehavior: CustomScrollBehavior(),
            onGenerateRoute: AppRouter.generateRoute,
            home: SplashPage(),
          ),
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
