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
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository.dart';

const Color kYellowLight = Color(0xFFFFF9C4);
const Color kYellow = Color(0xFFFFEB3B);
const Color kOrange = Color(0xFFFF9800);
const Color kOrangeDark = Color(0xFFF57C00);
const Color kBrown = Color(0xFF8D6E63);
const Color kWhite = Colors.white;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showHomeTutorial = false;
  final List<Map<String, String>> _homeTutorialSteps = [
    {
      'title': 'Bienvenue sur l\'accueil !',
      'desc': 'Retrouvez ici vos contacts, formations et notifications importantes.',
    },
    {
      'title': 'Vos contacts',
      'desc': 'Accédez rapidement aux personnes clés pour votre formation.',
    },
    {
      'title': 'Formations recommandées',
      'desc': 'Découvrez les formations sélectionnées pour vous chaque jour.',
    },
  ];

  late final ContactRepository _contactRepository;
  late final FormationRepository _formationRepository;
  late final AuthRepository _authRepository;
  List<Contact> _contacts = [];
  List<Formation> _randomFormations = [];
  bool _isLoading = true;
  String? _prenom;
  String? _nom;
  bool _isLoadingUser = true;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> _checkHomeTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('hasSeenHomeTutorial') ?? false;
    if (!seen) {
      setState(() => _showHomeTutorial = true);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkHomeTutorialSeen();
    _initializeRepositories();
    _loadData();
    _loadConnectedUser();
    _initFcmListener();
  }

  void _initializeRepositories() {
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );

    _contactRepository = ContactRepository(apiClient: apiClient);
    _formationRepository = FormationRepository(apiClient: apiClient);
    _authRepository = AuthRepository(
      remoteDataSource: AuthRemoteDataSourceImpl(
        apiClient: apiClient,
        storage: const FlutterSecureStorage(),
      ),
      storage: const FlutterSecureStorage(),
    );
  }

  Future<void> _loadConnectedUser() async {
    try {
      final user = await _authRepository.getMe();
      if (mounted) {
        setState(() {
          _prenom = user?.stagiaire?.prenom;
          _nom = user?.name;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur en chargeant l\'utilisateur connecté: $e');
      if (mounted) setState(() => _isLoadingUser = false);
    }
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
    setState(() => _isLoading = true);
    try {
      final contacts = await _contactRepository.getContacts();
      final formationsRaw = await _formationRepository.getRandomFormations(3);
      final formations = formationsRaw.whereType<Formation>().toList();

      setState(() {
        _contacts = contacts;
        _randomFormations = formations;
      });
    } catch (e) {
      debugPrint("Erreur pendant _loadData: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final theme = Theme.of(context);

    return Stack(
      children: [
        Scaffold(
          body: (_isLoading || _isLoadingUser)
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: _loadData,
            color: theme.primaryColor,
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(child: _buildWelcomeSection(isTablet)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                  child: _buildSectionTitle(
                    context,
                    title: 'Formations recommandées',
                    icon: LucideIcons.bookOpen,
                  ),
                ),
                SliverToBoxAdapter(
                  child: RandomFormationsWidget(
                    formations: _randomFormations,
                    onRefresh: _loadData,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                  child: _buildSectionWithButton(
                    context,
                    title: 'Mes contacts',
                    icon: LucideIcons.user,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContactPage(contacts: _contacts),
                      ),
                    ),
                  ),
                ),
                _buildContactsList(isTablet),
              ],
            ),
          ),
        ),
        // if (_showHomeTutorial)
        //   TutorialOverlay(...),
      ],
    );
  }

  Widget _buildWelcomeSection(bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kYellowLight, kWhite, kOrange.withOpacity(0.2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kOrange.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: kYellow, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: isTablet ? 60 : 48,
              height: isTablet ? 60 : 48,
              decoration: BoxDecoration(
                color: kYellowLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.megaphone,
                color: kOrange,
                size: isTablet ? 36 : 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, ${_prenom ?? 'Utilisateur'} ${_nom ?? ''} !',
                    style: TextStyle(
                      fontSize: isTablet ? 26 : 20,
                      fontWeight: FontWeight.bold,
                      color: kBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prêt pour une nouvelle journée d\'apprentissage ?',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: kBrown.withOpacity(0.7),
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

  Widget _buildSectionTitle(
      BuildContext context, {
        required String title,
        required IconData icon,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: kYellow, shape: BoxShape.circle),
              child: Icon(icon, color: kOrangeDark, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kBrown,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionWithButton(
      BuildContext context, {
        required String title,
        required IconData icon,
        required VoidCallback onPressed,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kYellow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: kOrangeDark, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kBrown,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: kOrange,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onPressed,
              child: const Text('Voir tous->'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList(bool isTablet) {
    if (_contacts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: kYellowLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kYellow, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: kOrange.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Aucun contact disponible',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: kBrown),
              ),
            ),
          ),
        ),
      );
    }

    // Filtrage des contacts par type
    final wantedTypes = {'Commercial', 'Formateur', 'pole_relation_client'};
    final filteredContacts = <String, Contact>{};

    for (final contact in _contacts) {
      if (wantedTypes.contains(contact.type)) {
        final roleKey = contact.type.toLowerCase().contains('relation')
            ? 'relation'
            : contact.type.toLowerCase();

        if (!filteredContacts.containsKey(roleKey)) {
          filteredContacts[roleKey] = contact;
        }
      }
    }

    // Ordonnancement des contacts
    final orderedContacts = [
      if (filteredContacts.containsKey('commercial')) filteredContacts['commercial']!,
      if (filteredContacts.containsKey('formateur')) filteredContacts['formateur']!,
      if (filteredContacts.containsKey('relation')) filteredContacts['relation']!,
    ];

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
              (context, index) => ContactCard(
            contact: orderedContacts[index],
            showFormations: false,
          ),
          childCount: orderedContacts.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 2 : 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isTablet ? 2.5 : 2.6,
        ),
      ),
    );
  }
}