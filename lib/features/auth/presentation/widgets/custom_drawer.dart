import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wizi_learn/features/auth/presentation/bloc/auth_event.dart';
import 'package:wizi_learn/features/auth/presentation/bloc/auth_state.dart';
import '../../../../core/constants/route_constants.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          // Header avec photo et infos utilisateur
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is Authenticated) {
                return Container(
                  width: double.infinity, // Prend toute la largeur
                  padding: const EdgeInsets.only(top: 40, bottom: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea( // Ajout de SafeArea pour éviter les encochements
                    child: Column(
                      children: [
                        // Avatar avec effet de bordure
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            backgroundImage: state.user.image != null
                                ? CachedNetworkImageProvider(
                              AppConstants.getUserImageUrl(state.user.image!),
                            )
                                : null,
                            child: state.user.image == null
                                ? Text(
                              state.user.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Nom et email - avec contraste amélioré
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              Text(
                                state.user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 20, // Taille augmentée
                                  shadows: [
                                  Shadow(
                                  color: Colors.black45,
                                  blurRadius: 2,
                                  offset: Offset(1, 1),
                                  )],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                state.user.email,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95), // Opacité augmentée
                                  fontSize: 14,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 1,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }              return Container(
                padding: const EdgeInsets.only(top: 40, bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Wizi Learn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),

          // Contenu du menu
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Section infos stagiaire
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (state is Authenticated &&
                          state.user.stagiaire != null) {
                        return _buildInfoCard(context, state);
                      }
                      return const SizedBox();
                    },
                  ),

                  // Séparateur
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      color: theme.dividerColor.withOpacity(0.3),
                      thickness: 1,
                      indent: 24,
                      endIndent: 24,
                    ),
                  ),

                  // Menu principal
                  _buildMenuSection(
                    context,
                    title: 'Navigation',
                    items: [
                      _MenuItem(
                        icon: Icons.school,
                        label: 'Mes formations',
                        route: RouteConstants.myTrainings,
                      ),
                      _MenuItem(
                        icon: Icons.timeline,
                        label: 'Mes Progrès',
                        route: RouteConstants.myProgress,
                      ),
                      _MenuItem(
                        icon: Icons.quiz,
                        label: 'Mes Quiz',
                        route: RouteConstants.quiz,
                      ),
                    ],
                  ),

                  // Section aide et informations
                  _buildMenuSection(
                    context,
                    title: 'Aide & Informations',
                    items: [
                      _MenuItem(
                        icon: Icons.help_center,
                        label: 'FAQ',
                        route: RouteConstants.faq,
                      ),
                      _MenuItem(
                        icon: Icons.mail_rounded,
                        label: 'Contact & Remarques',
                        route: RouteConstants.contact,
                      ),
                      _MenuItem(
                        icon: Icons.account_tree,
                        label: 'CGV',
                        route: RouteConstants.terms,
                      ),
                      _MenuItem(
                        icon: Icons.settings_cell,
                        label: "Manuel d'utilisation",
                        route: RouteConstants.userManual,
                      ),
                      _MenuItem(
                        icon: Icons.recommend_outlined,
                        label: "Remerciements",
                        route: RouteConstants.thanks,
                      ),
                      _MenuItem(
                        icon: Icons.shield,
                        label: "Politique de Confidentialité",
                        route: RouteConstants.privacy,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bouton de déconnexion
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
              ),
            ),
            child: _buildDrawerItem(
              context,
              icon: Icons.logout,
              label: 'Déconnexion',
              iconColor: Colors.red,
              onTap: () {
                context.read<AuthBloc>().add(LogoutEvent());
                Navigator.pushReplacementNamed(context, RouteConstants.login);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Authenticated state) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Mes informations',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                icon: Icons.person,
                title: 'Identité',
                value:
                    '${state.user.stagiaire!.civilite} ${state.user.stagiaire!.prenom}',
              ),
              _buildInfoTile(
                icon: Icons.phone,
                title: 'Téléphone',
                value: state.user.stagiaire!.telephone,
              ),
              _buildInfoTile(
                icon: Icons.location_on,
                title: 'Adresse',
                value:
                    '${state.user.stagiaire!.adresse}, ${state.user.stagiaire!.codePostal} ${state.user.stagiaire!.ville}',
              ),
              _buildInfoTile(
                icon: Icons.calendar_today,
                title: 'Formation depuis',
                value: state.user.stagiaire!.dateDebutFormation,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          ...items.map(
            (item) => _buildDrawerItem(
              context,
              icon: item.icon,
              label: item.label,
              onTap: () {
                Navigator.pushReplacementNamed(context, item.route);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (iconColor ?? theme.colorScheme.primary).withOpacity(
                      0.1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;

  _MenuItem({required this.icon, required this.label, required this.route});
}
