import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FormateurDrawerMenu extends StatelessWidget {
  final VoidCallback onLogout;

  const FormateurDrawerMenu({
    Key? key,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFF7931E).withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFF7931E),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Trainer Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wizi-Learn Platform',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildMenuSection('Main', [
            _MenuItem(
              icon: Icons.dashboard,
              label: 'Dashboard',
              onTap: () => Navigator.pop(context),
            ),
            _MenuItem(
              icon: Icons.people,
              label: 'My Trainees',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/formateur/stagiaires');
              },
            ),
            _MenuItem(
              icon: Icons.trending_up,
              label: 'Progress Analytics',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/formateur/analytics');
              },
            ),
          ]),
          _buildMenuSection('Management', [
            _MenuItem(
              icon: Icons.assignment,
              label: 'Tasks & Assignments',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/formateur/tasks');
              },
            ),
            _MenuItem(
              icon: Icons.announcement,
              label: 'Announcements',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/formateur/send-notification');
              },
            ),
            _MenuItem(
              icon: Icons.leaderboard,
              label: 'Leaderboard',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/formateur/classement');
              },
            ),
            _MenuItem(
              icon: Icons.assessment,
              label: 'Quizzes',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/formateur/quizzes');
              },
            ),
          ]),
          _buildMenuSection('Settings', [
            _MenuItem(
              icon: Icons.settings,
              label: 'Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/formateur/settings');
              },
            ),
            _MenuItem(
              icon: Icons.help,
              label: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/formateur/help');
              },
            ),
            _MenuItem(
              icon: Icons.logout,
              label: 'Logout',
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF7931E),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        ...items.map((item) => _buildMenuItem(item)).toList(),
      ],
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return ListTile(
      leading: Icon(
        item.icon,
        color: item.isDestructive ? Colors.red : const Color(0xFFF7931E),
      ),
      title: Text(
        item.label,
        style: TextStyle(
          color: item.isDestructive ? Colors.red : Colors.white,
          fontSize: 14,
        ),
      ),
      onTap: item.onTap,
      hoverColor: Colors.grey.withOpacity(0.1),
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
