import 'package:flutter/material.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        actions: [
          // Icône points utilisateur
          IconButton(
            icon: Badge(
              label: const Text('150'), // À remplacer par des données dynamiques
              child: const Icon(Icons.monetization_on),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/user-points');
            },
          ),
          // Icône notifications
          IconButton(
            icon: Badge(
              label: const Text('3'), // À remplacer par des données dynamiques
              child: const Icon(Icons.notifications),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          ...?actions, // Conserve les actions existantes
        ],
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          // Bannière de parrainage
          if (showBanner)
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/sponsorship');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                width: double.infinity,
                color: Colors.amber,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Parraine et gagne 50€ !',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Icon(Icons.arrow_forward, color: Colors.grey[800]),
                  ],
                ),
              ),
            ),
          // Contenu principal
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: onTabSelected,
      ),
    );
  }
}