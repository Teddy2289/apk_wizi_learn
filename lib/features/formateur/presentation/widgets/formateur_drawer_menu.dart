import 'package:flutter/material.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';

class FormateurDrawerMenu extends StatelessWidget {
  final VoidCallback onLogout;

  const FormateurDrawerMenu({
    Key? key,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: FormateurTheme.border,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: FormateurTheme.accent.withOpacity(0.1),
                  child: const Icon(
                    Icons.person_outline,
                    size: 32,
                    color: FormateurTheme.accentDark,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tableau de bord',
                  style: TextStyle(
                    color: FormateurTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                 Text(
                  'Espace Formateur',
                  style: TextStyle(
                    color: FormateurTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildMenuSection('PRINCIPAL', [
            _MenuItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              onTap: () => Navigator.pop(context),
            ),
            _MenuItem(
              icon: Icons.people_outline,
              label: 'Mes Stagiaires',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/formateur/stagiaires');
              },
            ),
             _MenuItem(
              icon: Icons.bar_chart_outlined,
              label: 'Analytiques',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/formateur/analytiques');
              },
            ),
             _MenuItem(
              icon: Icons.video_library_outlined,
              label: 'Vidéos',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, RouteConstants.formateurVideos);
              },
            ),
          ]),
          _buildMenuSection('GESTION', [
            _MenuItem(
              icon: Icons.campaign_outlined,
              label: 'Communications',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/formateur/send-notification');
              },
            ),
            _MenuItem(
              icon: Icons.leaderboard_outlined,
              label: 'Classement',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/formateur/classement');
              },
            ),
            _MenuItem(
              icon: Icons.quiz_outlined,
              label: 'Quiz',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/formateur/quizzes');
              },
            ),
            _MenuItem(
              icon: Icons.assignment_outlined,
              label: 'Suivi Demandes',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, RouteConstants.formateurSuiviDemandes);
              },
            ),
            _MenuItem(
              icon: Icons.card_giftcard_outlined,
              label: 'Suivi Parrainage',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, RouteConstants.formateurSuiviParrainage);
              },
            ),

          ]),
          _buildMenuSection('PARAMÈTRES', [
             _MenuItem(
              icon: Icons.settings_outlined,
              label: 'Configuration',
              onTap: () {
                 Navigator.pop(context);
                // Navigator.pushNamed(context, '/formateur/settings');
              },
            ),
             _MenuItem(
              icon: Icons.help_outline,
              label: 'Aide & Support',
              onTap: () {
                 Navigator.pop(context);
                // Navigator.pushNamed(context, '/formateur/help');
              },
            ),
            _MenuItem(
              icon: Icons.logout_rounded,
              label: 'Déconnexion',
              onTap: onLogout,
              isDestructive: true,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(
            title,
            style: const TextStyle(
              color: FormateurTheme.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items.map((item) => _buildMenuItem(item)).toList(),
      ],
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(
        item.icon,
        color: item.isDestructive ? FormateurTheme.error : FormateurTheme.textSecondary,
        size: 22,
      ),
      title: Text(
        item.label,
        style: TextStyle(
          color: item.isDestructive ? FormateurTheme.error : FormateurTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: item.onTap,
      hoverColor: FormateurTheme.background,
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}
