import 'package:flutter/material.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';

class DashboardFooter extends StatelessWidget {
  const DashboardFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF3F4F6), // gray-100 equivalent
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          // Content Columns
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 768;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildBrandColumn()),
                    const SizedBox(width: 32),
                    Expanded(child: _buildUsefulLinks(context)),
                    const SizedBox(width: 32),
                    Expanded(child: _buildSupportLinks(context)),
                    const SizedBox(width: 32),
                    Expanded(child: _buildLegalLinks(context)),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrandColumn(),
                    const SizedBox(height: 32),
                    _buildUsefulLinks(context),
                    const SizedBox(height: 32),
                    _buildSupportLinks(context),
                    const SizedBox(height: 32),
                    _buildLegalLinks(context),
                  ],
                );
              }
            },
          ),
          
          const SizedBox(height: 32),
          const Divider(color: Color(0xFFE5E7EB)), // gray-200
          const SizedBox(height: 24),
          
          // Copyright
          Text(
            '© ${DateTime.now().year} Wizi Learn - Tous droits réservés',
            style: const TextStyle(
              color: Color(0xFF6B7280), // gray-500
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBrandColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo (using text/icon placeholder if image assumes assets)
        Image.asset(
          'assets/images/logo.png', // Assuming standard asset path
          height: 40,
          errorBuilder: (_, __, ___) => const Row(
            children: [
              Icon(Icons.school, color: FormateurTheme.accentDark),
              SizedBox(width: 8),
              Text('Wizi Learn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Plateforme d'apprentissage interactive et ludique pour développer vos compétences.",
          style: TextStyle(
            color: Color(0xFF4B5563), // gray-600
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildUsefulLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Liens utiles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _FooterLink(label: 'Accueil', onTap: () => Navigator.pushNamed(context, RouteConstants.formateurDashboard)),
        _FooterLink(label: 'Catalogue', onTap: () => Navigator.pushNamed(context, RouteConstants.formations)),
        _FooterLink(label: 'Classement', onTap: () => Navigator.pushNamed(context, RouteConstants.classement)),
        _FooterLink(label: 'Agenda', onTap: () {
          // Navigator.pushNamed(context, '/agenda'); // Route not yet ready
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agenda: Bientôt disponible')),
          );
        }),
      ],
    );
  }

  Widget _buildSupportLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _FooterLink(label: 'Contact', onTap: () => Navigator.pushNamed(context, RouteConstants.contact)),
        _FooterLink(label: 'FAQ', onTap: () => Navigator.pushNamed(context, RouteConstants.faq)),
      ],
    );
  }

  Widget _buildLegalLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Légal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _FooterLink(label: "Conditions d'utilisation", onTap: () => Navigator.pushNamed(context, RouteConstants.terms)),
        _FooterLink(label: 'Politique de confidentialité', onTap: () => Navigator.pushNamed(context, RouteConstants.privacy)),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4B5563), // gray-600
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
