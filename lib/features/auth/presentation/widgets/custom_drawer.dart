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
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header simplifié avec juste les infos essentielles
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is Authenticated) {
                return Container(
                  color: const Color(0xFFFEB823),
                  padding: const EdgeInsets.only(
                    top: 40,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
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
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.user.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  state.user.email,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
              return const DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF0066CC)),
                child: Text(
                  'Wizi Learn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.school,
                  label: 'Mes formations',
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      RouteConstants.myTrainings,
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.timeline,
                  label: 'Mes Progrès',
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      RouteConstants.myProgress,
                    );
                  },
                ),

                // Section des informations supplémentaires du stagiaire
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is Authenticated && state.user.stagiaire != null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mes informations',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    icon: Icons.person,
                                    text:
                                    '${state.user.stagiaire!.civilite} ${state.user.stagiaire!.prenom}',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    icon: Icons.phone,
                                    text: state.user.stagiaire!.telephone,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    icon: Icons.location_on,
                                    text:
                                    '${state.user.stagiaire!.adresse}, ${state.user.stagiaire!.codePostal} ${state.user.stagiaire!.ville}',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    icon: Icons.calendar_today,
                                    text:
                                    'Formation depuis: ${state.user.stagiaire!.dateDebutFormation}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),

          // Bouton de déconnexion
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: _buildDrawerItem(
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}