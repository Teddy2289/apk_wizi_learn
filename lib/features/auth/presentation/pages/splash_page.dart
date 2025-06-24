import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wizi_learn/features/auth/presentation/bloc/auth_event.dart';
import 'package:wizi_learn/features/auth/presentation/bloc/auth_state.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/constants/route_constants.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Color?> _gradientAnimation;
  late final Animation<double> _textScaleAnimation;
  late final AuthBloc _authBloc;
  bool _authCheckCompleted = false;

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuad),
    );

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.05),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.05, end: 0.0),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuad),
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.7), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _gradientAnimation = ColorTween(
      begin: const Color(0xFFFEB823),
      end: Colors.deepOrange,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _textScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuad),
    );

    // Démarrer l'animation principale
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _authBloc.add(CheckAuthEvent());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          _navigateToDashboard();
        } else if (state is Unauthenticated || state is AuthError) {
          _navigateToLogin();
        }
      },
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _gradientAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _gradientAnimation.value!,
                    _gradientAnimation.value!.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: child,
            );
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animé
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _scaleAnimation,
                    _rotationAnimation,
                    _fadeAnimation,
                  ]),
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Image.asset(
                            'assets/images/logo1.png',
                            width: 150,
                            height: 150,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // Texte animé
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _textScaleAnimation,
                    _fadeAnimation,
                  ]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _textScaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        // child: Text(
                        //   'Wizi Learn',
                        //   style: Theme.of(
                        //     context,
                        //   ).textTheme.headlineMedium?.copyWith(
                        //     color: Colors.white,
                        //     fontWeight: FontWeight.bold,
                        //     letterSpacing: 1.5,
                        //     shadows: [
                        //       Shadow(
                        //         blurRadius: 10,
                        //         color: Colors.black.withOpacity(0.3),
                        //         offset: const Offset(2, 2),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                      ),
                    );
                  },
                ),

                // const SizedBox(height: 40),

                // Barre de progression animée
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _controller.value,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.8),
                          ),
                          minHeight: 8,
                        ),
                      );
                    },
                  ),
                ),

                // Texte de chargement
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Text(
                        'Chargement...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDashboard() {
    debugPrint('Navigation vers le dashboard');
    if (!_authCheckCompleted) {
      _authCheckCompleted = true;
      Navigator.pushReplacementNamed(context, RouteConstants.dashboard);
    }
  }

  void _navigateToLogin() {
    if (!_authCheckCompleted) {
      _authCheckCompleted = true;
      Navigator.pushReplacementNamed(context, RouteConstants.login);
    }
  }
}
