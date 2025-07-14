import 'package:flutter/material.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';

class ContactFaqPage extends StatefulWidget {
  const ContactFaqPage({super.key});

  @override
  State<ContactFaqPage> createState() => _ContactFAQPageState();
}

class _ContactFAQPageState extends State<ContactFaqPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedProblemType;
  final List<String> _problemTypes = [
    'Problème technique',
    'Question sur une formation',
    'Facturation',
    'Autre'
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contact & FAQ'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                Navigator.pushReplacementNamed(
                    context, RouteConstants.dashboard),
          ),
          backgroundColor: isDarkMode
              ? theme.appBarTheme.backgroundColor
              : Colors.white,
          elevation: 1,
          foregroundColor: isDarkMode ? Colors.white : Colors.black87,
          bottom: const TabBar(
              tabs: [
          Tab(icon: Icon(Icons.help_outline)),
          Tab(icon: Icon(Icons.mail_outlined)
          ),],
        ),
      ),
      body: TabBarView(
        children: [
          // Onglet FAQ
          _buildFAQSection(theme),

          // Onglet Contact
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contactez notre équipe de support',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Votre email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre email';
                      }
                      if (!value.contains('@')) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Objet
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Objet',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un objet';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Type de problème
                  DropdownButtonFormField<String>(
                    value: _selectedProblemType,
                    decoration: const InputDecoration(
                      labelText: 'Type de problème',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _problemTypes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedProblemType = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner un type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Message
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Votre message',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un message';
                      }
                      if (value.length < 20) {
                        return 'Veuillez détailler votre demande';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Pièce jointe
                  OutlinedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Ajouter une pièce jointe'),
                    onPressed: _attachFile,
                  ),
                  const SizedBox(height: 24),

                  // Bouton d'envoi
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _submitForm,
                      child: const Text(
                          'ENVOYER LE MESSAGE', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),);
  }

  Widget _buildFAQSection(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Foire Aux Questions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          _buildFAQItem(
            question: "Comment accéder à mes formations ?",
            answer: "Toutes vos formations sont disponibles dans l'onglet 'Mes formations' du menu principal. Cliquez sur une formation pour la démarrer.",
          ),

          _buildFAQItem(
            question: "Comment réinitialiser mon mot de passe ?",
            answer: "Sur la page de connexion, cliquez sur 'Mot de passe oublié'. Vous recevrez un email avec un lien pour réinitialiser votre mot de passe.",
          ),

          _buildFAQItem(
            question: "Comment contacter le support technique ?",
            answer: "Utilisez le formulaire de contact dans l'onglet 'Contact' de cette page. Nous répondons sous 24h en semaine.",
          ),

          _buildFAQItem(
            question: "Où voir ma progression ?",
            answer: "Votre progression est visible dans l'onglet 'Mes Progrès'. Vous y trouverez vos statistiques et vos certifications obtenues.",
          ),

          _buildFAQItem(
            question: "Comment obtenir une attestation de formation ?",
            answer: "Les attestations sont générées automatiquement lorsque vous terminez une formation. Elles sont disponibles dans votre espace 'Mes Certifications'.",
          ),

          const SizedBox(height: 24),
          Text(
            "Vous ne trouvez pas de réponse à votre question ?",
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Utilisez notre formulaire de contact pour poser votre question directement à notre équipe.",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(answer),
          ),
        ],
      ),
    );
  }

  void _attachFile() {
    // Implémentez la logique d'attachement de fichier ici
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Fonctionnalité de pièce jointe en développement')),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _sendMessage();
    }
  }

  void _sendMessage() {
    // Implémentez l'envoi du message ici
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message envoyé avec succès')),
    );
    // Réinitialisation du formulaire
    _emailController.clear();
    _subjectController.clear();
    _messageController.clear();
    setState(() {
      _selectedProblemType = null;
    });
  }
}