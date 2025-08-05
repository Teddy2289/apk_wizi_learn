import 'package:flutter/material.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Politique de Confidentialité'),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed:
              () => Navigator.pushReplacementNamed(
            context,
            RouteConstants.dashboard,
          ),
        ),
        backgroundColor: isDarkMode ? theme.appBarTheme.backgroundColor : Colors.white,
        elevation: 1,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'POLITIQUE DE CONFIDENTIALITÉ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dernière mise à jour : 01/01/2023\n'
                  'Wizi Learn - SARL au capital de 1000€\n'
                  '8, rue Evariste Galois, 86130 Jaunay-Marigny\n'
                  'Siren 883 622 151\n'
                  'Délégué à la protection des données : Alexandre Florek',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Article 1 - Introduction
            _buildPrivacyArticle(
              title: '1. INTRODUCTION',
              content: 'La présente Politique de Confidentialité décrit comment Wizi Learn collecte, utilise et protège les informations que vous nous fournissez lorsque vous utilisez notre application et nos services.\n\n'
                  'En utilisant nos services, vous acceptez les pratiques décrites dans cette politique. Nous nous engageons à protéger votre vie privée conformément au Règlement Général sur la Protection des Données (RGPD) et aux lois françaises en vigueur.',
            ),

            // Article 2 - Données collectées
            _buildPrivacyArticle(
              title: '2. DONNÉES COLLECTÉES',
              content: 'Nous collectons les données suivantes :\n\n'
                  '- Données d\'identification (nom, prénom, email)\n'
                  '- Données professionnelles (poste, entreprise)\n'
                  '- Données de formation (progression, résultats aux quiz)\n'
                  '- Données techniques (adresse IP, type d\'appareil, logs)\n'
                  '- Données de paiement (uniquement pour les formations payantes, via notre prestataire de paiement sécurisé)\n\n'
                  'Certaines données sont collectées automatiquement via des cookies et technologies similaires pour améliorer notre service.',
            ),

            // Article 3 - Finalités du traitement
            _buildPrivacyArticle(
              title: '3. FINALITÉS DU TRAITEMENT',
              content: 'Vos données sont utilisées pour :\n\n'
                  '- Fournir et personnaliser nos services\n'
                  '- Gérer votre compte utilisateur\n'
                  '- Suivre votre progression dans les formations\n'
                  '- Vous envoyer des informations importantes\n'
                  '- Améliorer notre plateforme et développer de nouvelles fonctionnalités\n'
                  '- Prévenir et détecter les fraudes\n'
                  '- Respecter nos obligations légales',
            ),

            // Article 4 - Base légale
            _buildPrivacyArticle(
              title: '4. BASE LÉGALE DU TRAITEMENT',
              content: 'Le traitement de vos données repose sur :\n\n'
                  '- L\'exécution du contrat pour les données nécessaires à la fourniture de nos services\n'
                  '- Votre consentement pour les communications marketing\n'
                  '- Notre intérêt légitime pour améliorer nos services\n'
                  '- Les obligations légales pour les données que nous devons conserver',
            ),

            // Article 5 - Partage des données
            _buildPrivacyArticle(
              title: '5. PARTAGE DES DONNÉES',
              content: 'Vos données peuvent être partagées avec :\n\n'
                  '- Nos prestataires techniques (hébergeur, solution de paiement)\n'
                  '- Les organismes financeurs (OPCO, CPF) lorsque applicable\n'
                  '- Les autorités compétentes si requis par la loi\n\n'
                  'Nous exigeons de tous nos partenaires qu\'ils respectent des standards stricts de protection des données. Aucun transfert hors UE n\'est effectué.',
            ),

            // Article 6 - Sécurité
            _buildPrivacyArticle(
              title: '6. SÉCURITÉ DES DONNÉES',
              content: 'Nous mettons en œuvre des mesures techniques et organisationnelles appropriées pour protéger vos données :\n\n'
                  '- Chiffrement des données sensibles\n'
                  '- Contrôles d\'accès stricts\n'
                  '- Audit régulier de nos systèmes\n'
                  '- Formation de notre personnel\n\n'
                  'En cas de violation de données, nous nous engageons à notifier les autorités compétentes et les utilisateurs concernés dans les délais légaux.',
            ),

            // Article 7 - Conservation
            _buildPrivacyArticle(
              title: '7. DURÉE DE CONSERVATION',
              content: 'Nous conservons vos données :\n\n'
                  '- Pendant la durée de votre compte utilisateur\n'
                  '- 3 ans après la dernière activité pour les données de compte\n'
                  '- 10 ans pour les données comptables (obligation légale)\n'
                  '- Jusqu\'à retrait du consentement pour les données marketing\n\n'
                  'Passés ces délais, les données sont anonymisées ou supprimées de manière sécurisée.',
            ),

            // Article 8 - Vos droits
            _buildPrivacyArticle(
              title: '8. VOS DROITS',
              content: 'Conformément au RGPD, vous disposez des droits suivants :\n\n'
                  '- Droit d\'accès à vos données\n'
                  '- Droit de rectification\n'
                  '- Droit à l\'effacement ("droit à l\'oubli")\n'
                  '- Droit à la limitation du traitement\n'
                  '- Droit à la portabilité des données\n'
                  '- Droit d\'opposition\n'
                  '- Droit de retirer votre consentement\n\n'
                  'Pour exercer ces droits, contactez notre DPO à l\'adresse : support@wizi-learn.com. Nous répondrons dans un délai maximum d\'un mois.',
            ),

            // Article 9 - Cookies
            _buildPrivacyArticle(
              title: '9. COOKIES ET TECHNOLOGIES SIMILAIRES',
              content: 'Notre application utilise :\n\n'
                  '- Cookies essentiels au fonctionnement\n'
                  '- Cookies d\'analyse pour mesurer l\'audience\n'
                  '- Cookies de personnalisation\n\n'
                  'Vous pouvez configurer vos préférences concernant les cookies dans les paramètres de votre compte ou de votre navigateur.',
            ),

            // Article 10 - Modifications
            _buildPrivacyArticle(
              title: '10. MODIFICATIONS DE LA POLITIQUE',
              content: 'Nous pouvons mettre à jour cette politique pour refléter les évolutions légales ou de nos services. Les modifications prendront effet dès leur publication. Nous vous informerons des changements significatifs.',
            ),

            // Article 11 - Contact
            _buildPrivacyArticle(
              title: '11. CONTACT',
              content: 'Pour toute question concernant cette politique ou vos données personnelles :\n\n'
                  'Délégué à la Protection des Données\n'
                  'Wizi Learn\n'
                  '8, rue Evariste Galois\n'
                  '86130 Jaunay-Marigny\n'
                  'Email : support@wizi-learn.com\n'
                  'Téléphone : 09 72 51 29 04',
            ),

            const SizedBox(height: 24),
            Text(
              'En utilisant nos services, vous reconnaissez avoir lu et compris cette Politique de Confidentialité.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyArticle({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 15, height: 1.5),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }
}