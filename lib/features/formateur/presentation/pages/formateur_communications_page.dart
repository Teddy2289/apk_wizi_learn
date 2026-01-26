import 'package:flutter/material.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';
import 'package:wizi_learn/features/formateur/presentation/widgets/formateur_drawer_menu.dart';
import 'package:wizi_learn/features/formateur/presentation/widgets/notification_panel.dart';
import 'package:wizi_learn/features/formateur/presentation/widgets/email_panel.dart';

class FormateurCommunicationsPage extends StatefulWidget {
  const FormateurCommunicationsPage({super.key});

  @override
  State<FormateurCommunicationsPage> createState() => _FormateurCommunicationsPageState();
}

class _FormateurCommunicationsPageState extends State<FormateurCommunicationsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormateurTheme.background,
      appBar: AppBar(
        title: const Text('Communications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: FormateurTheme.textPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
        foregroundColor: FormateurTheme.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: FormateurTheme.accentDark,
          unselectedLabelColor: FormateurTheme.textTertiary,
          indicatorColor: FormateurTheme.accentDark,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.notifications_outlined), text: 'NOTIFICATIONS FCM'),
            Tab(icon: Icon(Icons.mail_outline), text: 'EMAILS'),
          ],
        ),
      ),
      drawer: FormateurDrawerMenu(onLogout: () {}),
      body: TabBarView(
        controller: _tabController,
        children: const [
          NotificationPanel(),
          EmailPanel(),
        ],
      ),
    );
  }
}
