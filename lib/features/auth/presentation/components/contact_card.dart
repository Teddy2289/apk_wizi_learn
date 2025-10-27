import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    debugPrint(
      'Avatar debug - Image: ${contact.image}, Prenom: ${contact.prenom}, Name: ${contact.name}',
    );

    final hasProfileImage =
        contact.image != null &&
        contact.image!.isNotEmpty &&
        contact.image != 'null';

    if (hasProfileImage) {
      try {
        String imageUrl = AppConstants.getUserImageUrl(contact.image!);
        debugPrint('Full Image URL: $imageUrl');

        return CachedNetworkImage(
          imageUrl: imageUrl,
          imageBuilder:
              (context, imageProvider) =>
                  CircleAvatar(radius: radius, backgroundImage: imageProvider),
          placeholder: (context, url) => _buildFallbackAvatar(radius),
          errorWidget: (context, url, error) {
            debugPrint('CachedNetworkImage error: $error for URL: $url');
            return _buildFallbackAvatar(radius);
          },
        );
      } catch (e) {
        debugPrint('Error processing image URL: $e');
        return _buildFallbackAvatar(radius);
      }
    } else {
      return _buildFallbackAvatar(radius);
    }
  }

  Widget _buildFallbackAvatar(double radius) {
    String initiales = '';

    // Priorité au prénom + nom pour les initiales
    if (contact.prenom?.isNotEmpty == true && contact.name.isNotEmpty) {
      initiales = '${contact.prenom![0]}${contact.name[0]}'.toUpperCase();
    } else if (contact.prenom?.isNotEmpty == true) {
      initiales = contact.prenom![0].toUpperCase();
    } else if (contact.name.isNotEmpty) {
      initiales = contact.name[0].toUpperCase();
    } else {
      initiales = '?';
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.amber.shade100,
      child: Text(
        initiales,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: Colors.brown.shade700,
        ),
      ),
    );
  }

  // Résolution de l'URL de l'image
  String _resolveImageUrl(String path) {
    return AppConstants.getUserImageUrl(path);
  }

  // Formatage du nom avec civilité - CORRECTION : civilite n'est plus nullable
  // Formatage du nom avec civilité et prénom
  String _getFormattedName() {
    String nom =
        contact.name.isNotEmpty
            ? contact.name
                .toUpperCase() // Garder le nom en majuscules comme dans les logs
            : '';

    String prenom =
        contact.prenom?.isNotEmpty == true
            ? '${contact.prenom![0].toUpperCase()}${contact.prenom!.substring(1).toLowerCase()}'
            : '';

    String nomComplet = '';
    if (prenom.isNotEmpty && nom.isNotEmpty) {
      nomComplet = '$prenom $nom';
    } else if (prenom.isNotEmpty) {
      nomComplet = prenom;
    } else if (nom.isNotEmpty) {
      nomComplet = nom;
    } else {
      nomComplet = 'Inconnu';
    }

    // Ne pas afficher la civilité à côté du nom/prénom dans la card
    return nomComplet;
  }

  // Formatage du rôle avec distinction masculin/féminin - CORRECTION : utiliser le rôle du backend
  String _getFormattedRole() {
    // Priorité au rôle, sinon utiliser le type
    final roleOrType = contact.role ?? contact.type;
    final lowerRole = roleOrType.toLowerCase();
    final civiliteRaw = contact.civilite?.toLowerCase() ?? '';

    // Détection du genre basé sur la civilité — plus robuste
    // Normaliser la civilité en tokens (ex: 'Mme', 'Madame', 'Mlle', 'F', 'Féminin', ...)
    String normalized = civiliteRaw.replaceAll(
      RegExp(r"[^a-z0-9éèêàçù-]"),
      ' ',
    );
    final tokens =
        normalized.split(RegExp(r"\s+")).where((t) => t.isNotEmpty).toList();
    final feminineTokens = {
      'mme',
      'mme.',
      'madame',
      'mlle',
      'mlle.',
      'mademoiselle',
      'f',
      'féminin',
      'feminin',
    };

    final isFeminin = tokens.any((t) => feminineTokens.contains(t));

    // Si le rôle indique explicitement 'formatrice' nous considérons aussi le genre féminin
    if (lowerRole.contains('formatrice') || lowerRole.contains('formateur')) {
      return isFeminin ? 'Formatrice' : 'Formateur';
    } else if (lowerRole.contains('commercial')) {
      return isFeminin ? 'Commerciale' : 'Commercial';
    } else if (lowerRole.contains('sav') ||
        lowerRole.contains('pole_sav') ||
        lowerRole.contains('Chargée Administration des Ventes') ||
        lowerRole.contains('Responsable suivi formation & SAV & Parrainage') ||
        lowerRole.contains('responsable pôle formateur') ||
        lowerRole.contains('assistante adv') ||
        lowerRole.contains('adv')) {
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
    return lowerRole.contains('formateur') || lowerRole.contains('formatrice');
  }
}
