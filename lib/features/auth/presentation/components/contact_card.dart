import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
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
              // Avatar avec image de profil ou initiales
              _buildAvatar(avatarRadius),
              SizedBox(width: isSmallScreen ? 8 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nom avec civilité
                    Text(
                      _getFormattedName(),
                      style: TextStyle(
                        fontSize: nameFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),

                    // Rôle avec distinction masculin/féminin - CORRECTION : utiliser le rôle du backend
                    Row(
                      children: [
                        Icon(
                          Icons.work,
                          size: iconSize,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: isSmallScreen ? 3 : 6),
                        Text(
                          _getFormattedRole(),
                          style: TextStyle(
                            fontSize: infoFontSize,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),

                    // Téléphone
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

                    // Email - phrase cliquable
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
                            message: 'Envoyer un email',
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
                                'Envoyer un email',
                                style: TextStyle(
                                  fontSize: infoFontSize,
                                  color: Colors.blue.shade700,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Formations pour les formateurs/formatrices
                    if (showFormations &&
                        _isFormateur() &&
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
              // Bouton d'appel
              IconButton(
                icon: Icon(
                  Icons.phone_forwarded,
                  color: Colors.brown.shade600,
                  size: iconSize + 4,
                ),
                onPressed: () async {
                  if (contact.telephone.isEmpty) return;
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

  // Construction de l'avatar avec image ou initiales - CORRECTION : utiliser 'image' au lieu de 'photo'
  Widget _buildAvatar(double radius) {
    // Vérifier si une image de profil existe
    final hasProfileImage = contact.image != null && contact.image!.isNotEmpty;

    if (hasProfileImage) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(_resolveImageUrl(contact.image!)),
        onBackgroundImageError: (exception, stackTrace) {
          // En cas d'erreur de chargement, on utilise les initiales
        },
        child: _buildFallbackAvatar(radius),
      );
    } else {
      return _buildFallbackAvatar(radius);
    }
  }

  // Avatar de secours avec initiales
  Widget _buildFallbackAvatar(double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.amber.shade100,
      child: Text(
        contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: radius,
          fontWeight: FontWeight.bold,
          color: Colors.brown.shade300,
        ),
      ),
    );
  }

  // Résolution de l'URL de l'image
  String _resolveImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    // Utiliser votre méthode AppConstants.getUserImageUrl si elle existe
    return AppConstants.getUserImageUrl(
      path,
    ); // À adapter selon votre configuration
  }

  // Formatage du nom avec civilité - CORRECTION : civilite n'est plus nullable
  String _getFormattedName() {
    String name =
        contact.name.isNotEmpty
            ? contact.name[0].toUpperCase() + contact.name.substring(1)
            : 'Inconnu';

    // Ajouter la civilité si disponible
    if (contact.civilite != null && contact.civilite!.isNotEmpty) {
      return '${contact.civilite} $name';
    }

    return name;
  }

  // Formatage du rôle avec distinction masculin/féminin - CORRECTION : utiliser le rôle du backend
  String _getFormattedRole() {
    // Priorité au rôle, sinon utiliser le type
    final roleOrType = contact.role ?? contact.type;
    final lowerRole = roleOrType.toLowerCase();
    final civilite = contact.civilite?.toLowerCase() ?? '';

    // Détection du genre basé sur la civilité
    final isFeminin =
        civilite.contains('M.') ||
        civilite.contains('Mme.') ||
        civilite.contains('Mlle.');

    if (lowerRole.contains('formateur')) {
      return isFeminin ? 'Formatrice' : 'Formateur';
    } else if (lowerRole.contains('commercial')) {
      return isFeminin ? 'Commerciale' : 'Commercial';
    } else if (lowerRole.contains('sav') || lowerRole.contains('pole_sav')) {
      return 'Pôle SAV';
    } else if (lowerRole.contains('relation') ||
        lowerRole.contains('pole_relation')) {
      return 'Pôle relation client';
    } else {
      // Fallback : utiliser le rôle/type tel quel
      return roleOrType.isNotEmpty
          ? roleOrType[0].toUpperCase() + roleOrType.substring(1)
          : 'Contact';
    }
  }

  // Vérification si c'est un formateur/formatrice
  bool _isFormateur() {
    final roleOrType = contact.role ?? contact.type;
    final lowerRole = roleOrType.toLowerCase();
    return lowerRole.contains('formateur');
  }
}
