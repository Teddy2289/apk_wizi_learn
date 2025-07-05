import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wizi_learn/features/auth/data/models/contact_model.dart';

class ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback? onRefresh;

  const ContactCard({super.key, required this.contact, this.onRefresh});

  Future<void> _handleEmailTap(BuildContext context) async {
    final emailUrl = Uri(
      scheme: 'mailto',
      path: contact.user.email,
      queryParameters: {'subject': 'Contact depuis Wizi Learn'},
    );

    try {
      await launchUrl(emailUrl);
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: contact.user.email));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email copié - Ouvrez votre application mail'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleCallTap(BuildContext context) async {
    final cleanedNumber = contact.telephone.replaceAll(RegExp(r'[^0-9+]'), '');
    final telUrl = Uri(scheme: 'tel', path: cleanedNumber);

    try {
      await launchUrl(telUrl);
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: cleanedNumber));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Numéro copié - Ouvrez votre appli téléphone'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatRole(String role) {
    switch (role.toLowerCase()) {
      case 'pole_relation_client':
        return 'Conseiller client';
      case 'commercial':
        return 'Commercial';
      case 'formateur':
        return 'Formateur';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.sizeOf(context).width < 350;

    final dimensions = _CardDimensions(
      avatarRadius: isSmallScreen ? 20.0 : 28.0,
      nameSize: isSmallScreen ? 14.0 : 16.0,
      iconSize: isSmallScreen ? 16.0 : 20.0,
      infoSize: isSmallScreen ? 12.0 : 14.0,
      padding: isSmallScreen ? 12.0 : 16.0,
      spacing: isSmallScreen ? 4.0 : 8.0,
    );

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 6 : 8,
        horizontal: isSmallScreen ? 8 : 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onRefresh,
        child: Padding(
          padding: EdgeInsets.all(dimensions.padding),
          child: Row(
            children: [
              CircleAvatar(
                radius: dimensions.avatarRadius,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Text(
                  contact.prenom.isNotEmpty
                      ? contact.prenom[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: dimensions.avatarRadius * 0.8,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              SizedBox(width: dimensions.spacing * 2),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.prenom,
                      style: TextStyle(
                        fontSize: dimensions.nameSize,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: dimensions.spacing),

                    _InfoRow(
                      icon: Icons.work_outline,
                      text: _formatRole(contact.role),
                      dimensions: dimensions,
                      color: theme.colorScheme.secondary,
                    ),

                    SizedBox(height: dimensions.spacing),

                    GestureDetector(
                      onTap: () => _handleCallTap(context),
                      child: _InfoRow(
                        icon: Icons.phone_android_outlined,
                        text: contact.telephone,
                        dimensions: dimensions,
                      ),
                    ),

                    SizedBox(height: dimensions.spacing),

                    if (contact.user.email.isNotEmpty)
                      GestureDetector(
                        onTap: () => _handleEmailTap(context),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: dimensions.iconSize * 0.8,
                              color: theme.colorScheme.primary,
                            ),
                            SizedBox(width: dimensions.spacing),
                            Flexible(
                              child: Text(
                                contact.user.email,
                                style: TextStyle(
                                  fontSize: dimensions.infoSize,
                                  color: theme.colorScheme.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              IconButton(
                icon: Icon(
                  Icons.call_outlined,
                  size: dimensions.iconSize,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () => _handleCallTap(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final _CardDimensions dimensions;
  final Color? color;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.dimensions,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: dimensions.iconSize * 0.8,
          color: color ?? theme.textTheme.bodySmall?.color,
        ),
        SizedBox(width: dimensions.spacing),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: dimensions.infoSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CardDimensions {
  final double avatarRadius;
  final double nameSize;
  final double iconSize;
  final double infoSize;
  final double padding;
  final double spacing;

  const _CardDimensions({
    required this.avatarRadius,
    required this.nameSize,
    required this.iconSize,
    required this.infoSize,
    required this.padding,
    required this.spacing,
  });
}