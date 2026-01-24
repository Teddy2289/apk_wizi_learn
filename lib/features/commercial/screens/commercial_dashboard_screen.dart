import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/commercial_colors.dart';
import 'email_sender_screen.dart';
import 'notification_sender_screen.dart';
import 'stats_dashboard_screen.dart';
import 'online_users_screen.dart';
import '../../formateur/presentation/pages/formateur_suivi_demandes_page.dart';
import '../../formateur/presentation/pages/formateur_suivi_parrainage_page.dart';


class CommercialDashboardScreen extends StatefulWidget {
  const CommercialDashboardScreen({super.key});

  @override
  State<CommercialDashboardScreen> createState() =>
      _CommercialDashboardScreenState();
}

class _CommercialDashboardScreenState extends State<CommercialDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {

      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Interface Commerciale',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: CommercialColors.orangeGradient,
          ),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,

          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              icon: Icon(LucideIcons.mail, size: 20),
              text: 'Emails',
            ),
            Tab(
              icon: Icon(LucideIcons.bell, size: 20),
              text: 'Notifications',
            ),
            Tab(
              icon: Icon(LucideIcons.trendingUp, size: 20),
              text: 'Statistiques',
            ),
            Tab(
              icon: Icon(LucideIcons.users, size: 20),
              text: 'En ligne',
            ),
            Tab(
              icon: Icon(LucideIcons.clipboardList, size: 20),
              text: 'Suivi Inscr.',
            ),
            Tab(
              icon: Icon(LucideIcons.gift, size: 20),
              text: 'Suivi Parr.',
            ),
          ],

        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          EmailSenderScreen(),
          NotificationSenderScreen(),
          StatsDashboardScreen(),
          OnlineUsersScreen(),
          FormateurSuiviDemandesPage(),
          FormateurSuiviParrainagePage(),
        ],

      ),
    );
  }
}
