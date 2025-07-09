import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/constants/route_constants.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _OnSplashPage();
}

class _OnSplashPage extends State<SplashPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Apprentissage Mobile",
      "description":
          "Accédez à des leçons courtes et efficaces où que vous soyez. Optimisez votre temps libre pour développer vos compétences.",
      "imageAsset": "assets/images/splash1.jpeg",
      "icon": "school",
    },
    {
      "title": "Suivi de Progrès",
      "description":
          "Visualisez votre évolution avec des statistiques détaillées et des récompenses motivantes pour maintenir votre engagement.",
      "imageAsset": "assets/images/splash2.jpeg",
      "icon": "insights",
    },
    {
      "title": "Contenu Expert",
      "description":
          "Bénéficiez de contenus créés par des experts pour maximiser votre apprentissage et atteindre vos objectifs rapidement.",
      "imageAsset": "assets/images/splash3.jpeg",
      "icon": "verified_user",
    },
  ];

  void _goToNextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToAuth();
    }
  }

  void _skipOnboarding() {
    _navigateToAuth();
  }

  void _navigateToAuth() {
    Navigator.pushReplacementNamed(context, RouteConstants.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFEB823), Colors.deepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip Button (top right)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    'Passer',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Page View Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _onboardingData.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = _onboardingData[index];
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.08,
                          vertical: 20,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Image with shadow and border
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  item['imageAsset']!,
                                  width: size.width * 0.8,
                                  height: size.height * 0.4,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Icon
                            Icon(
                              _getIconData(item['icon']),
                              size: 40,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 20),

                            // Title
                            Text(
                              item['title']!,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),

                            // Description
                            Text(
                              item['description']!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                height: 1.5,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Page Indicator
              SmoothPageIndicator(
                controller: _pageController,
                count: _onboardingData.length,
                effect: const WormEffect(
                  dotColor: Colors.white38,
                  activeDotColor: Colors.white,
                  dotHeight: 10,
                  dotWidth: 10,
                  spacing: 8,
                ),
              ),
              const SizedBox(height: 30),

              // Next/Get Started Button
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.15,
                  vertical: 20,
                ),
                child: ElevatedButton(
                  onPressed: _goToNextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(size.width * 0.7, 50),
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.2),
                  ),
                  child: Text(
                    _currentPage == _onboardingData.length - 1
                        ? "Commencer"
                        : "Suivant",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school;
      case 'insights':
        return Icons.insights;
      case 'verified_user':
        return Icons.verified_user;
      default:
        return Icons.help_outline;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
