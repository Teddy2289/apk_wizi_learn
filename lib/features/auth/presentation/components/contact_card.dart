import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/features/auth/data/models/contact_model.dart';

// Nouvelle palette de couleurs harmonieuse
const Color kPrimaryBlue = Color(0xFF3D9BE9);
const Color kPrimaryBlueLight = Color(0xFFE8F4FE);
const Color kPrimaryBlueDark = Color(0xFF2A7BC8);

const Color kSuccessGreen = Color(0xFFABDA96);
const Color kSuccessGreenLight = Color(0xFFF0F9ED);
const Color kSuccessGreenDark = Color(0xFF7BBF5E);

const Color kAccentPurple = Color(0xFF9392BE);
const Color kAccentPurpleLight = Color(0xFFF5F4FF);
const Color kAccentPurpleDark = Color(0xFF6A6896);

const Color kWarningOrange = Color(0xFFFFC533);
const Color kWarningOrangeLight = Color(0xFFFFF8E8);
const Color kWarningOrangeDark = Color(0xFFE6A400);

const Color kErrorRed = Color(0xFFA55E6E);
const Color kErrorRedLight = Color(0xFFFBEAED);
const Color kErrorRedDark = Color(0xFF8C4454);

const Color kNeutralWhite = Colors.white;
const Color kNeutralGrey = Color(0xFFF8F9FA);
const Color kNeutralGreyDark = Color(0xFF6C757D);
const Color kNeutralBlack = Color(0xFF212529);

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
    final isTablet = width > 600;

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 4 : 6,
        horizontal: isSmallScreen ? 8 : 12,
      ),
      child: Card(
        elevation: 4,
        color: kNeutralWhite,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showContactDetails(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kNeutralWhite, kNeutralGrey.withOpacity(0.3)],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar avec badge de statut
                  _buildAvatarSection(isSmallScreen, isTablet),
                  SizedBox(width: isSmallScreen ? 12 : 16),

                  // Informations du contact
                  Expanded(
                    child: _buildContactInfo(context, isSmallScreen, isTablet),
                  ),

                  // Boutons d'action
                  if (!isSmallScreen)
                    _buildActionButtons(context, isSmallScreen),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(bool isSmallScreen, bool isTablet) {
    final avatarSize = isSmallScreen ? 40.0 : (isTablet ? 70.0 : 56.0);

    return Stack(
      children: [
        // Avatar principal
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _getRoleColor().withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: _buildAvatar(avatarSize / 2),
        ),

        // Badge de statut en bas à droite
        // Positioned(
        //   bottom: 0,
        //   right: 0,
        //   child: Container(
        //     width: isSmallScreen ? 12 : 16,
        //     height: isSmallScreen ? 12 : 16,
        //     decoration: BoxDecoration(
        //       color: _getAvailabilityColor(),
        //       shape: BoxShape.circle,
        //       border: Border.all(color: kNeutralWhite, width: 2),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Widget _buildContactInfo(
    BuildContext context,
    bool isSmallScreen,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nom et rôle
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getFormattedName(),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : (isTablet ? 18 : 16),
                      fontWeight: FontWeight.bold,
                      color: kNeutralBlack,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getRoleColor().withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      _getFormattedRole(),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        fontWeight: FontWeight.w600,
                        color: _getRoleColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Boutons d'action pour petits écrans
            if (isSmallScreen) _buildCompactActionButtons(context),
          ],
        ),

        const SizedBox(height: 12),

        // Informations de contact
        _buildContactDetails(context, isSmallScreen),

        // Formations (si applicable)
        if (showFormations &&
            _isFormateur() &&
            contact.formations != null &&
            contact.formations!.isNotEmpty)
          _buildFormationsSection(isSmallScreen),
      ],
    );
  }

  Widget _buildContactDetails(BuildContext context, bool isSmallScreen) {
    return Column(
      children: [
        // Email
        _buildContactRow(
          icon: Icons.email_rounded,
          text: 'Envoyer un email',
          onTap: () => _launchEmail(context),
          isSmallScreen: isSmallScreen,
          isClickable: true,
        ),

        const SizedBox(height: 6),

        // Téléphone
        _buildContactRow(
          icon: Icons.phone_rounded,
          text:
              contact.telephone.isNotEmpty
                  ? contact.telephone
                  : 'Non renseigné',
          onTap:
              contact.telephone.isNotEmpty ? () => _launchPhone(context) : null,
          isSmallScreen: isSmallScreen,
          isClickable: contact.telephone.isNotEmpty,
        ),
      ],
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
    required bool isSmallScreen,
    required bool isClickable,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              Icon(
                icon,
                size: isSmallScreen ? 14 : 16,
                color: isClickable ? kPrimaryBlue : kNeutralGreyDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: isClickable ? kPrimaryBlue : kNeutralGreyDark,
                    decoration:
                        isClickable ? TextDecoration.none : TextDecoration.none,
                    fontWeight:
                        isClickable ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormationsSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kSuccessGreenLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kSuccessGreen.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.school_rounded,
                    size: isSmallScreen ? 14 : 16,
                    color: kSuccessGreenDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Formations',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      color: kSuccessGreenDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (contact.formations!.length > 1)
                Text(
                  '${contact.formations!.length} formations disponibles',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 13,
                    color: kNeutralGreyDark,
                  ),
                )
              else
                ...contact.formations!.map((f) {
                  final dates = _formatFormationDates(
                    f['dateDebut'],
                    f['dateFin'],
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f['titre'] ?? 'Formation',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 13,
                          fontWeight: FontWeight.w500,
                          color: kNeutralBlack,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (dates.isNotEmpty)
                        Text(
                          dates,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: kNeutralGreyDark,
                          ),
                        ),
                    ],
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isSmallScreen) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Bouton d'appel
        _buildActionButton(
          icon: Icons.phone_in_talk_rounded,
          color: const Color.fromARGB(255, 233, 161, 61),
          onPressed: () => _launchPhone(context),
          tooltip: 'Appeler',
          isSmallScreen: isSmallScreen,
        ),

        const SizedBox(height: 8),

        // Bouton email
        _buildActionButton(
          icon: Icons.email_rounded,
          color: kSuccessGreen,
          onPressed: () => _launchEmail(context),
          tooltip: 'Envoyer un email',
          isSmallScreen: isSmallScreen,
        ),
        // Bouton détails
      ],
    );
  }

  Widget _buildCompactActionButtons(BuildContext context) {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.phone_rounded,
          color: const Color.fromARGB(255, 233, 161, 61),
          onPressed: () => _launchPhone(context),
          tooltip: 'Appeler',
          isSmallScreen: true,
          size: 32,
        ),
        const SizedBox(width: 4),
        _buildActionButton(
          icon: Icons.email_rounded,
          color: kSuccessGreen,
          onPressed: () => _launchEmail(context),
          tooltip: 'Email',
          isSmallScreen: true,
          size: 32,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
    required bool isSmallScreen,
    double size = 40,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, size: isSmallScreen ? 14 : 18, color: kNeutralWhite),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tight(Size(size, size)),
        ),
      ),
    );
  }

  // Construction de l'avatar
  Widget _buildAvatar(double radius) {
    final hasProfileImage =
        contact.image != null &&
        contact.image!.isNotEmpty &&
        contact.image != 'null';

    if (hasProfileImage) {
      try {
        String imageUrl = AppConstants.getUserImageUrl(contact.image!);
        return CachedNetworkImage(
          imageUrl: imageUrl,
          imageBuilder:
              (context, imageProvider) =>
                  CircleAvatar(radius: radius, backgroundImage: imageProvider),
          placeholder: (context, url) => _buildFallbackAvatar(radius),
          errorWidget: (context, url, error) => _buildFallbackAvatar(radius),
        );
      } catch (e) {
        return _buildFallbackAvatar(radius);
      }
    } else {
      return _buildFallbackAvatar(radius);
    }
  }

  Widget _buildFallbackAvatar(double radius) {
    String initiales = '';

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
      backgroundColor: _getRoleColor().withOpacity(0.1),
      child: Text(
        initiales,
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
          color: _getRoleColor(),
        ),
      ),
    );
  }

  // Méthodes utilitaires (conservées de la version originale)
  String _getFormattedName() {
    String nom = contact.name.isNotEmpty ? contact.name : '';
    String prenom =
        contact.prenom?.isNotEmpty == true
            ? '${contact.prenom![0].toUpperCase()}${contact.prenom!.substring(1).toLowerCase()}'
            : '';

    if (prenom.isNotEmpty && nom.isNotEmpty) {
      return '$prenom ${nom[0]}.';
    } else if (prenom.isNotEmpty) {
      return prenom;
    } else if (nom.isNotEmpty) {
      return nom;
    } else {
      return 'Inconnu';
    }
  }

  String _getFormattedRole() {
    final roleOrType = contact.role ?? contact.type;
    final lowerRole = roleOrType.toLowerCase();
    final civiliteRaw = contact.civilite?.toLowerCase() ?? '';

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
      return roleOrType.isNotEmpty
          ? roleOrType[0].toUpperCase() + roleOrType.substring(1)
          : 'Contact';
    }
  }

  bool _isFormateur() {
    final roleOrType = contact.role ?? contact.type;
    final lowerRole = roleOrType.toLowerCase();
    return lowerRole.contains('formateur') || lowerRole.contains('formatrice');
  }

  String _formatFormationDates(String? dateDebut, String? dateFin) {
    String formatDate(String? date) {
      if (date == null || date.isEmpty) return '';
      try {
        final d = DateTime.parse(date);
        return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      } catch (_) {
        return date;
      }
    }

    final debut = formatDate(dateDebut);
    final fin = formatDate(dateFin);

    if (debut.isNotEmpty && fin.isNotEmpty) {
      return '$debut - $fin';
    } else if (debut.isNotEmpty) {
      return 'Début: $debut';
    } else if (fin.isNotEmpty) {
      return 'Fin: $fin';
    } else {
      return '';
    }
  }

  Color _getRoleColor() {
    final role = _getFormattedRole().toLowerCase();
    if (role.contains('formateur') || role.contains('formatrice')) {
      return kPrimaryBlue;
    } else if (role.contains('commercial')) {
      return kSuccessGreen;
    } else if (role.contains('sav')) {
      return kWarningOrange;
    } else if (role.contains('relation')) {
      return kAccentPurple;
    } else {
      return kNeutralGreyDark;
    }
  }


  // Méthodes de lancement
  Future<void> _launchEmail(BuildContext context) async {
    if (contact.email.isEmpty) return;
    final mailUrl = Uri(scheme: 'mailto', path: contact.email);
    try {
      await launchUrl(mailUrl);
    } catch (e) {
      _showErrorSnackbar(context, 'Impossible d\'ouvrir l\'application mail.');
    }
  }

  Future<void> _launchPhone(BuildContext context) async {
    if (contact.telephone.isEmpty) return;
    final telUrl = Uri(scheme: 'tel', path: contact.telephone);
    try {
      await launchUrl(telUrl);
    } catch (e) {
      _showErrorSnackbar(
        context,
        'Impossible d\'ouvrir l\'application d\'appel.',
      );
    }
  }

  void _showContactDetails(BuildContext context) {
    // Pourrait ouvrir un modal ou une page de détails
    // Pour l'instant, on garde la navigation simple
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kErrorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
