import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/features/auth/data/models/contact_model.dart';
import 'package:wizi_learn/features/auth/data/models/partner_model.dart';
import 'package:wizi_learn/features/auth/presentation/components/contact_card.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/features/auth/data/repositories/formation_repository.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/random_formations_widget.dart';
import 'package:wizi_learn/features/auth/data/models/formation_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/contact_repository.dart';

import '../../../../core/constants/route_constants.dart';

class ContactPage extends StatefulWidget {
  final List<Contact> contacts;
  final Partner? partner; // optionnel
  const ContactPage({super.key, required this.contacts, this.partner});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  late final FormationRepository _formationRepository;
  late final ContactRepository _contactRepository;
  Future<List<Formation>>? _formationsFuture;
  bool _showFormationsWidget = true;
  Partner? _partner;
  bool _isLoadingPartner = false;
  bool _isLoadingContacts = false;
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    final dio = Dio();
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(dio: dio, storage: storage);
    _formationRepository = FormationRepository(apiClient: apiClient);
    _contactRepository = ContactRepository(apiClient: apiClient);
    _loadFormations();
    _partner = widget.partner;
    if (_partner == null) {
      _fetchPartner();
    }
    // Charger les contacts si non fournis
    if (widget.contacts.isEmpty) {
      _loadContacts();
    } else {
      _contacts = widget.contacts;
    }
  }

  Future<void> _loadFormations() async {
    setState(() {
      _formationsFuture = _formationRepository.getRandomFormations(3);
    });
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoadingContacts = true);
    try {
      final contacts = await _contactRepository.getContacts();
      if (mounted) setState(() => _contacts = contacts);
    } catch (e) {
      // Optionnel: afficher un message d'erreur
    } finally {
      if (mounted) setState(() => _isLoadingContacts = false);
    }
  }

  Future<void> _fetchPartner() async {
    setState(() {
      _isLoadingPartner = true;
    });
    try {
      final dio = Dio();
      final storage = const FlutterSecureStorage();
      final apiClient = ApiClient(dio: dio, storage: storage);
      final response = await apiClient.get(AppConstants.partner);
      final data = response.data;
      setState(() {
        _partner = Partner.fromJson(
          data is Map<String, dynamic>
              ? data
              : (data as Map).cast<String, dynamic>(),
        );
      });
    } catch (e) {
      // ignore silently or show a snackbar
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPartner = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFEB823),
        title: const Text('Tous mes contacts'),
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
                if (_isLoadingContacts)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: LinearProgressIndicator(),
                  ),
                if (_isLoadingPartner) ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: LinearProgressIndicator(),
                  ),
                ],
                if (_partner != null) ...[
                  _PartnerHeader(partner: _partner!),
                  const SizedBox(height: 12),
                  if (_partner!.contacts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Contacts du partenaire',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ..._partner!.toContactList().map(
                      (c) => ContactCard(contact: c),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
                if (_contacts.isEmpty && !_isLoadingContacts)
                  const Center(child: Text('Aucun contact disponible'))
                else ...[
                  ..._contacts.map((contact) => ContactCard(contact: contact)),
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

class _PartnerHeader extends StatelessWidget {
  final Partner partner;
  const _PartnerHeader({required this.partner});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((partner.logo ?? '').isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _resolveImageUrl(partner.logo!),
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                ),
              )
            else
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business, color: Colors.grey),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          partner.identifiant,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          partner.type,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${partner.adresse}, ${partner.ville} (${partner.departement}) ${partner.codePostal}',
                  ),
                  if (partner.actif != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Row(
                        children: [
                          Icon(
                            partner.actif == true
                                ? Icons.check_circle
                                : Icons.cancel,
                            color:
                                partner.actif == true
                                    ? Colors.green
                                    : Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(partner.actif == true ? 'Actif' : 'Inactif'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _resolveImageUrl(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return AppConstants.getUserImageUrl(path);
}
