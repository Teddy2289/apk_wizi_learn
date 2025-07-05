import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/features/auth/data/models/contact_model.dart';
import 'package:wizi_learn/features/auth/presentation/components/contact_card.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/repositories/formation_repository.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/random_formations_widget.dart';
import 'package:wizi_learn/features/auth/data/models/formation_model.dart';

class ContactPage extends StatefulWidget {
  final List<Contact> contacts;
  const ContactPage({super.key, required this.contacts});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  late final FormationRepository _formationRepository;
  Future<List<Formation>>? _formationsFuture;
  bool _showFormationsWidget = true;

  @override
  void initState() {
    super.initState();
    final dio = Dio();
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(dio: dio, storage: storage);
    _formationRepository = FormationRepository(apiClient: apiClient);
    _loadFormations();
  }

  Future<void> _loadFormations() async {
    setState(() {
      _formationsFuture = _formationRepository.getRandomFormations(3);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFEB823),
        title: const Text('Tous mes contacts'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Retrouvez ici les contacts utiles mis à votre disposition dans le cadre de votre formation.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.brown.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                if (widget.contacts.isEmpty)
                  const Center(child: Text('Aucun contact disponible'))
                else ...[
                  ...widget.contacts.map(
                    (contact) => ContactCard(contact: contact),
                  ),
                ],
                const SizedBox(height: 24),
                if (_showFormationsWidget)
                  Stack(
                    children: [
                      FutureBuilder<List<Formation>>(
                        future: _formationsFuture,
                        builder: (context, snapshot) {
                          if (_formationsFuture == null ||
                              snapshot.connectionState ==
                                  ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Erreur lors du chargement des formations :  [200B]${snapshot.error}',
                              ),
                            );
                          }
                          final formations = snapshot.data ?? [];
                          if (formations.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Aucune formation trouvée.'),
                            );
                          }
                          return RandomFormationsWidget(formations: formations);
                        },
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _showFormationsWidget = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
