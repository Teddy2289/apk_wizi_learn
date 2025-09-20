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
  late final ContactRepository _contactRepository;
  late final FormationRepository _formationRepository;
  late final AuthRepository _authRepository;
  List<Contact> _contacts = [];
  List<Formation> _randomFormations = [];
  bool _isLoading = true;
  String? _prenom;
  String? _nom;
  bool _isLoadingUser = true;
  // Série de connexions (login streak)
  int _loginStreak = 0;
  bool _showStreakModal = false;
  bool _hideStreakFor7Days = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
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

      // récupérer la série de connexions depuis SharedPreferences (champ non présent dans l'entité stagiaire)
      int loginStreak = 0;
      try {
        final prefs = await SharedPreferences.getInstance();
        loginStreak = prefs.getInt('login_streak') ?? 0;
      } catch (_) {
        loginStreak = 0;
      }

      if (mounted) {
        setState(() {
          _prenom = user.stagiaire?.prenom;
          _nom = user.name;
          _loginStreak = loginStreak;
          _isLoadingUser = false;
        });

        // vérifier si on doit afficher la modale de streak (une fois par jour)
        await _checkAndShowStreakModal();
      }
    } catch (e) {
      debugPrint('Erreur en chargeant l\'utilisateur connecté: $e');
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _checkAndShowStreakModal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastShown = prefs.getString('lastStreakModalDate');
      final hideUntil = prefs.getString('streakModalHideUntil');
      // If user asked to hide until a later date, skip showing
      if (hideUntil != null) {
        try {
          final hideDate = DateTime.parse(hideUntil);
          final todayDate = DateTime.now();
          if (!todayDate.isAfter(hideDate)) {
            return;
          }
        } catch (_) {
          // ignore parse errors and continue
        }
      }
      final now = DateTime.now();
      final today =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      if (lastShown == today) return;
      if (_loginStreak > 0) {
        if (mounted) setState(() => _showStreakModal = true);
      }
    } catch (e) {
      // ignore storage errors
    }
  }

  Future<void> _closeStreakModal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await prefs.setString('lastStreakModalDate', today);
      if (_hideStreakFor7Days) {
        final hideUntilDate = now.add(const Duration(days: 7));
        final hideUntil =
            '${hideUntilDate.year.toString().padLeft(4, '0')}-${hideUntilDate.month.toString().padLeft(2, '0')}-${hideUntilDate.day.toString().padLeft(2, '0')}';
        await prefs.setString('streakModalHideUntil', hideUntil);
      } else {
        // if previously set, clear the hideUntil so modal can show again tomorrow
        await prefs.remove('streakModalHideUntil');
      }
    } catch (e) {
      // ignore
    }
    if (mounted) setState(() => _showStreakModal = false);
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
      final formationsRaw = await _formationRepository.getRandomFormations(6);
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
          body:
              (_isLoading || _isLoadingUser)
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                    onRefresh: _loadData,
                    color: theme.primaryColor,
                    child: CustomScrollView(
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        SliverToBoxAdapter(
                          child: _buildWelcomeSection(isTablet),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        SliverToBoxAdapter(
                          child: _buildPlatformPresentation(isTablet),
                        ),
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
                            onPressed:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            ContactPage(contacts: _contacts),
                                  ),
                                ),
                          ),
                        ),
                        _buildContactsList(isTablet),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        SliverToBoxAdapter(
                          child: _buildGameModesSection(isTablet),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  ),
        ),
        // Streak full-screen modal (une fois par jour)
        if (_showStreakModal)
          Positioned.fill(
            child: Material(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kOrange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kOrange.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '7 jours',
                              style: TextStyle(
                                color: kOrangeDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('🔥', style: TextStyle(fontSize: 56)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Série de connexions',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_loginStreak jour${_loginStreak > 1 ? 's' : ''} d\'affilée',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Continuez comme ça pour débloquer des récompenses 🎉',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: _hideStreakFor7Days,
                            onChanged: (val) {
                              if (mounted) {
                                setState(
                                  () => _hideStreakFor7Days = val ?? false,
                                );
                              }
                            },
                          ),
                          Expanded(
                            child: Text(
                              'Ne plus montrer pendant 7 jours',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kOrange,
                              foregroundColor: kWhite,
                            ),
                            onPressed: _closeStreakModal,
                            child: const Text('Continuer'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _closeStreakModal,
                            child: const Text('Fermer'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
          color: kYellowLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kYellow.withOpacity(0.5), width: 1),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onPressed,
              child: const Text('Voir tous'),
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
              color: kYellowLight.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kYellow.withOpacity(0.3), width: 0.5),
            ),
            child: Center(
              child: Text(
                'Aucun contact disponible',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: kBrown),
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
        final roleKey =
            contact.type.toLowerCase().contains('relation')
                ? 'relation'
                : contact.type.toLowerCase();

        if (!filteredContacts.containsKey(roleKey)) {
          filteredContacts[roleKey] = contact;
        }
      }
    }

    // Ordonnancement des contacts
    final orderedContacts = [
      if (filteredContacts.containsKey('commercial'))
        filteredContacts['commercial']!,
      if (filteredContacts.containsKey('formateur'))
        filteredContacts['formateur']!,
      if (filteredContacts.containsKey('relation'))
        filteredContacts['relation']!,
    ];

    // On phones keep the presentation as a vertical list. On tablets use
    // a horizontal carousel to preserve the sliding principle.
    final screenWidth = MediaQuery.of(context).size.width;
    final viewportFraction = isTablet ? 0.6 : 0.95;
    // Increase height for tablet carousel to avoid vertical overflow
    final carouselHeight = isTablet ? 170.0 : 140.0;

    if (!isTablet) {
      // Vertical list for smartphones
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ContactCard(
                contact: orderedContacts[index],
                showFormations: false,
              ),
            ),
            childCount: orderedContacts.length,
          ),
        ),
      );
    }

    // Tablet: horizontal carousel
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        child: SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            controller: PageController(viewportFraction: viewportFraction),
            itemCount: orderedContacts.length,
            padEnds: false,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final itemWidth = screenWidth * viewportFraction;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: SizedBox(
                  width: itemWidth,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: carouselHeight - 12,
                      ),
                      child: ContactCard(
                        contact: orderedContacts[index],
                        showFormations: false,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformPresentation(bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kYellowLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kYellow.withOpacity(0.5), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isTablet ? 50 : 40,
                  height: isTablet ? 50 : 40,
                  decoration: BoxDecoration(
                    color: kYellow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.rocket,
                    color: kOrangeDark,
                    size: isTablet ? 28 : 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Wizi Learn',
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: kBrown,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Votre plateforme d\'apprentissage intelligente',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: kBrown,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Découvrez des formations personnalisées, des quiz interactifs et des défis gamifiés pour progresser à votre rythme. Apprenez, jouez et excellez !',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: kBrown.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildFeatureChip('🎯 Personnalisé', isTablet),
                const SizedBox(width: 8),
                _buildFeatureChip('🏆 Gamifié', isTablet),
                const SizedBox(width: 8),
                _buildFeatureChip('📱 Mobile', isTablet),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String text, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 10,
        vertical: isTablet ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: kOrange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isTablet ? 12 : 10,
          fontWeight: FontWeight.w600,
          color: kOrangeDark,
        ),
      ),
    );
  }

  Widget _buildGameModesSection(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kYellow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.gamepad2,
                    color: kOrangeDark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Modes de Jeux',
                      style: TextStyle(
                        fontSize: isTablet ? 22 : 18,
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
        ),
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 16),
          child: isTablet ? _buildTabletGameModes() : _buildMobileGameModes(),
        ),
      ],
    );
  }

  Widget _buildMobileGameModes() {
    return Column(
      children: [
        _buildGameModeCard(
          icon: LucideIcons.target,
          title: 'Quiz Classique',
          description:
              'Questions à choix multiples pour tester vos connaissances',
          color: Colors.green,
          isTablet: false,
        ),
        const SizedBox(height: 12),
        _buildGameModeCard(
          icon: LucideIcons.crown,
          title: 'Quiz Aventure',
          description: 'Parcours gamifié avec récompenses et niveaux',
          color: Colors.purple,
          isTablet: false,
        ),
        const SizedBox(height: 12),
        _buildGameModeCard(
          icon: LucideIcons.clock,
          title: 'Défi Rapide',
          description: 'Quiz chronométrés pour des sessions express',
          color: Colors.red,
          isTablet: false,
        ),
      ],
    );
  }

  Widget _buildTabletGameModes() {
    return Row(
      children: [
        Expanded(
          child: _buildGameModeCard(
            icon: LucideIcons.target,
            title: 'Quiz Classique',
            description:
                'Questions à choix multiples pour tester vos connaissances',
            color: Colors.green,
            isTablet: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildGameModeCard(
            icon: LucideIcons.crown,
            title: 'Quiz Aventure',
            description: 'Parcours gamifié avec récompenses et niveaux',
            color: Colors.purple,
            isTablet: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildGameModeCard(
            icon: LucideIcons.clock,
            title: 'Défi Rapide',
            description: 'Quiz chronométrés pour des sessions express',
            color: Colors.red,
            isTablet: true,
          ),
        ),
      ],
    );
  }

  Widget _buildGameModeCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isTablet,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: kYellowLight.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kYellow.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isTablet ? 45 : 35,
                height: isTablet ? 45 : 35,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: isTablet ? 24 : 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: kBrown,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            description,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: kBrown.withOpacity(0.7),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
