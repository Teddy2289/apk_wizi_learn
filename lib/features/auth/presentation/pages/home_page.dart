import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/contact_model.dart';
import 'package:wizi_learn/features/auth/data/models/formation_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/contact_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/formation_repository.dart';
import 'package:wizi_learn/features/auth/presentation/pages/contact_page.dart';
import 'package:wizi_learn/features/auth/presentation/components/contact_card.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/random_formations_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ContactRepository _contactRepository;
  late final FormationRepository _formationRepository;
  List<Contact> _contacts = [];
  List<Formation> _randomFormations = [];
  bool _isLoading = true;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _contactRepository = ContactRepository(apiClient: apiClient);
    _formationRepository = FormationRepository(apiClient: apiClient);
    _loadData();
    _initFcmListener();
  }

  void _initFcmListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'channel_id',
              'Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final contacts = await _contactRepository.getContacts();
      // debugPrint("Contacts récupérés: ${contacts.map((c) => '${c.prenom} (${c.role})').toList()}");

      final formations = await _formationRepository.getRandomFormations(3);
      // debugPrint("Formations récupérées: ${formations.map((f) => f.titre).toList()}");

      setState(() {
        _contacts = contacts;
        _randomFormations = formations;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erreur pendant _loadData: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Seuil pour les petits écrans

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1, // Légère ombre pour la profondeur
        centerTitle: true,
        title: Text(
          'Bienvenue sur Wizi Learn',
          style: TextStyle(
            color: Colors.brown,
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _refreshData,
                child: CustomScrollView(
                  slivers: [
                    // Section Formations
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        isSmallScreen ? 16 : 24,
                        16,
                        isSmallScreen ? 16 : 24,
                        8,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Formations recommandées',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 20,
                                  color: const Color(0xFFB07661),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            RandomFormationsWidget(
                              formations: _randomFormations,
                              onRefresh: _refreshData,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Divider entre les sections
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 24,
                        vertical: 8,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Divider(color: Colors.grey[300], thickness: 1),
                      ),
                    ),

                    // Section Contacts
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        isSmallScreen ? 16 : 24,
                        8,
                        isSmallScreen ? 16 : 24,
                        16,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mes contacts',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                color: const Color(0xFFB07661),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            ContactPage(contacts: _contacts),
                                  ),
                                );
                              },
                              child: Text(
                                'Voir tous',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: isSmallScreen ? 14 : 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Liste des contacts ou message si vide
                    if (_contacts.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Aucun contact disponible',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16 : 24,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final wantedRoles = [
                              'commercial',
                              'formateur',
                              'pôle relation client',
                              'pôle_relation_client',
                            ];
                            final filteredContacts = <String, Contact>{};
                            for (final c in _contacts) {
                              final role = c.role.toLowerCase().replaceAll(
                                '_',
                                ' ',
                              );
                              if (wantedRoles.contains(role) &&
                                  !filteredContacts.containsKey(role)) {
                                filteredContacts[role] = c;
                              }
                            }
                            final contactsToShow =
                                filteredContacts.values.toList();

                            if (index >= contactsToShow.length) return null;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ContactCard(
                                contact: contactsToShow[index],
                                showFormations: false,
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
