import 'package:flutter/material.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
import 'package:wizi_learn/features/auth/presentation/constants/couleur_palette.dart';
import 'custom_app_bar.dart';
import 'custom_drawer.dart';
import 'custom_bottom_navbar.dart';

class CustomScaffold extends StatelessWidget {
  final Widget body;
  final List<Widget>? actions;
  final int currentIndex;
  final Function(int) onTabSelected;
  final bool showBanner;

  const CustomScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTabSelected,
    this.actions,
    this.showBanner = true,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Badge(
              label: const Text('15'),
              child: const Icon(Icons.star),
            ),
            onPressed: () {
              Navigator.pushNamed(context, RouteConstants.userPoints);
            },
          ),
          IconButton(
            icon: Badge(
              label: const Text('3'),
              child: const Icon(Icons.notifications),
            ),
            onPressed: () {
              Navigator.pushNamed(context, RouteConstants.notifications);
            },
          ),
          ...?actions,
        ],
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          if (showBanner)
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, RouteConstants.sponsorship);
              },
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent, // Utilisation de la couleur primaire
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.card_giftcard, size: 30, color: theme.colorScheme.onPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.onPrimary,
                          ),
                            children: [
                            const TextSpan(text: 'Parraine et gagne '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              margin: const EdgeInsets.only(bottom: 4), // Ajoute un espace en bas pour descendre le widget
                              child: Text(
                                '50€',
                                style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 2,
                                  offset: const Offset(1, 1),
                                  ),
                                ],
                                ),
                              ),
                              ),
                            ),
                            const TextSpan(text: ' !'),
                          ],
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onPrimary),
                  ],
                ),
              ),
            ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: onTabSelected,
        backgroundColor: theme.colorScheme.surface,
        selectedColor: theme.colorScheme.primary,
        unselectedColor: Colors.grey.shade600,
      ),
    );
  }

}