import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wizi_learn/features/auth/data/models/contact_model.dart';

class ContactCard extends StatelessWidget {
  final Contact contact;
  final bool showFormations;

  const ContactCard({
    super.key,
    required this.contact,
    this.showFormations = true,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 350;
    final avatarRadius = isSmallScreen ? 20.0 : 28.0;
    final nameFontSize = isSmallScreen ? 13.0 : 16.0;
    final iconSize = isSmallScreen ? 13.0 : 16.0;
    final infoFontSize = isSmallScreen ? 11.0 : 13.0;
    final cardPadding = isSmallScreen ? 10.0 : 16.0;
    return Card(
      elevation: 2,
      color: Colors.yellow.shade50,
      margin: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 4 : 6,
        horizontal: isSmallScreen ? 8 : 6,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Optionnel : Action sur le tap
        },
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.amber.shade100,
                child: Text(
                  contact.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: avatarRadius,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade300,
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      contact.name.isNotEmpty
                          ? contact.name[0].toUpperCase() +
                              contact.name.substring(1)
                          : 'Inconnu',
                      style: TextStyle(
                        fontSize: nameFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Row(
                      children: [
                        Icon(
                          Icons.work,
                          size: iconSize,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: isSmallScreen ? 3 : 6),
                        Text(
                          _getFormattedContactType(contact.type),
                          style: TextStyle(
                            fontSize: infoFontSize,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_android,
                          size: iconSize,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: isSmallScreen ? 3 : 6),
                        Expanded(
                          child: Text(
                            contact.telephone.isNotEmpty
                                ? contact.telephone
                                : 'Non renseigné',
                            style: TextStyle(fontSize: infoFontSize),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Row(
                      children: [
                        Icon(
                          Icons.email,
                          size: iconSize,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: isSmallScreen ? 3 : 6),
                        Expanded(
                          child: Tooltip(
                            message: 'Cliquer pour envoyer un email',
                            child: InkWell(
                              onTap: () async {
                                if (contact.email.isEmpty) return;
                                final mailUrl = Uri(
                                  scheme: 'mailto',
                                  path: contact.email,
                                );
                                try {
                                  await launchUrl(mailUrl);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Impossible d\'ouvrir l\'application mail.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                contact.email.isNotEmpty
                                    ? contact.email
                                    : 'Non renseigné',
                                style: TextStyle(
                                  fontSize: infoFontSize,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Ajout de l'affichage des formations pour les formateurs
                    if (showFormations &&
                        contact.type.toLowerCase().contains('formateur') &&
                        contact.formations != null &&
                        contact.formations!.isNotEmpty) ...[
                      SizedBox(height: isSmallScreen ? 2 : 6),
                      Text(
                        'Formations :',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: infoFontSize,
                          color: Colors.brown.shade700,
                        ),
                      ),
                      // If many formations, show a compact summary to avoid vertical overflow
                      if (contact.formations!.length > 1) ...[
                        SizedBox(height: 4),
                        Text(
                          '${contact.formations!.length} formations disponibles',
                          style: TextStyle(
                            fontSize: infoFontSize,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        // Show detailed single formation info
                        ...contact.formations!.map((f) {
                          String formatDate(String? date) {
                            if (date == null || date.isEmpty) return '';
                            try {
                              final d = DateTime.parse(date);
                              return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                            } catch (_) {
                              return date;
                            }
                          }

                          final debut = formatDate(f['dateDebut']);
                          final fin = formatDate(f['dateFin']);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f['titre'] ?? '',
                                style: TextStyle(fontSize: infoFontSize),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '($debut - $fin)',
                                style: TextStyle(
                                  fontSize: infoFontSize,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        }),
                      ],
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.phone_forwarded,
                  color: Colors.brown.shade600,
                  size: iconSize + 4,
                ),
                onPressed: () async {
                  final telUrl = Uri(scheme: 'tel', path: contact.telephone);
                  try {
                    await launchUrl(telUrl);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Impossible d\'ouvrir l\'application d\'appel.',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFormattedContactType(String type) {
    final lowerType = type.toLowerCase();

    if (lowerType.contains('formateur')) {
      return 'Formateur';
    } else if (lowerType.contains('sav') || lowerType.contains('pole_sav')) {
      return 'Pôle SAV';
    } else if (lowerType.contains('commercial')) {
      return 'Commercial';
    } else if (lowerType.contains('relation') || lowerType.contains('pole_relation')) {
      return 'Pôle relation client';
    } else {
      // Fallback : capitaliser la première lettre pour les types inconnus
      return type.isNotEmpty
          ? type[0].toUpperCase() + type.substring(1)
          : 'Contact';
    }
  }
}
