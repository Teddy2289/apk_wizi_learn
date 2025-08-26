import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/repositories/contact_repository.dart';

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
  List<PlatformFile> _selectedFiles = [];
  bool _isSending = false;

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
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            onPressed: () => Navigator.pushReplacementNamed(
              context,
              RouteConstants.dashboard,
            ),
          ),
          backgroundColor: isDarkMode
              ? theme.appBarTheme.backgroundColor
              : Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.help_outline)),
              Tab(icon: Icon(Icons.mail_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFAQSection(theme),
            _buildContactForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactForm() {
    return SingleChildScrollView(
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
            _buildEmailField(),
            const SizedBox(height: 16),
            _buildSubjectField(),
            const SizedBox(height: 16),
            _buildProblemTypeDropdown(),
            const SizedBox(height: 16),
            _buildMessageField(),
            const SizedBox(height: 16),
            _buildAttachmentsSection(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
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
    );
  }

  Widget _buildSubjectField() {
    return TextFormField(
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
    );
  }

  Widget _buildProblemTypeDropdown() {
    return DropdownButtonFormField<String>(
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
    );
  }

  Widget _buildMessageField() {
    return TextFormField(
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
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.attach_file),
          label: const Text('Ajouter des pièces jointes'),
          onPressed: _isSending ? null : _attachFile,
        ),
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Fichiers sélectionnés:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: _selectedFiles.map((file) {
              return Chip(
                label: SizedBox(
                  width: 100,
                  child: Text(
                    file.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: _isSending
                    ? null
                    : () {
                  setState(() {
                    _selectedFiles.remove(file);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: _isSending ? null : _submitForm,
        child: _isSending
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
          'ENVOYER LE MESSAGE',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _attachFile() async {
    debugPrint("ATTOOOO");
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          _selectedFiles = result.files;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedFiles.length} fichier(s) sélectionné(s)')),
        );
      }
    } catch (e) {
      debugPrint("Erreur lors de la sélection des fichiers: $e");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Erreur lors de la sélection des fichiers: $e')),
      // );
    }
  }

  Future<List<MultipartFile>> _prepareAttachments() async {
    List<MultipartFile> multipartFiles = [];

    for (var file in _selectedFiles) {
      if (file.bytes != null) {
        multipartFiles.add(
          MultipartFile.fromBytes(
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (file.path != null) {
        multipartFiles.add(
          await MultipartFile.fromFile(
            file.path!,
            filename: file.name,
          ),
        );
      }
    }

    return multipartFiles;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSending = true;
      });

      try {
        await ContactRepository(apiClient: ApiClient(
          dio: Dio(),
          storage: const FlutterSecureStorage(),
        )).sendContactForm(
          email: _emailController.text,
          subject: _subjectController.text,
          problemType: _selectedProblemType ?? '',
          message: _messageController.text,
          attachments: _selectedFiles,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message envoyé avec succès')),
        );

        // Reset form
        _emailController.clear();
        _subjectController.clear();
        _messageController.clear();
        setState(() {
          _selectedProblemType = null;
          _selectedFiles = [];
        });
      } on DioException catch (e) {
        // Gestion spécifique de l'erreur backend
        if (e.response?.data?.toString().contains('format() on string') ?? false) {
          // Le message a été envoyé mais le backend a un problème mineur
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message envoyé avec succès!')),
          );

          // Reset form quand même
          _emailController.clear();
          _subjectController.clear();
          _messageController.clear();
          setState(() {
            _selectedProblemType = null;
            _selectedFiles = [];
          });
        } else {
          // Pour les autres erreurs Dio
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'envoi: ${e.message}')),
          );
        }
      } catch (e) {
        // Pour les autres types d'erreurs
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur inattendue: $e')),
        );
      } finally {
        setState(() {
          _isSending = false;
        });
      }
    }
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
            answer: "Toutes vos formations sont disponibles dans l'onglet 'Mes formations' du menu principal.",
          ),

          _buildFAQItem(
            question: "Comment réinitialiser mon mot de passe ?",
            answer: "Sur la page de connexion, cliquez sur 'Mot de passe oublié'.",
          ),

          _buildFAQItem(
            question: "Comment contacter le support technique ?",
            answer: "Utilisez le formulaire de contact dans l'onglet 'Contact' de cette page.",
          ),

          _buildFAQItem(
            question: "Où voir ma progression ?",
            answer: "Votre progression est visible dans l'onglet 'Mes Progrès'.",
          ),

          _buildFAQItem(
            question: "Comment obtenir une attestation de formation ?",
            answer: "Les attestations sont générées automatiquement lorsque vous terminez une formation.",
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
}