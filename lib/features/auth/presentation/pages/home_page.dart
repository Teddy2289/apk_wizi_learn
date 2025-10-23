import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
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
import 'package:wizi_learn/features/home/presentation/widgets/how_to_play.dart';
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
  late final ApiClient _apiClient;
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
  // Bienvenue: affichage une seule fois par jour
  bool _showWelcomeBlock = false;

  // États pour le modal de succès d'inscription
  bool _showInscriptionSuccessModal = false;
  String _inscriptionSuccessMessage = '';
  String _inscriptionFormationTitle = '';

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _primeStreakFromLocal();
    _initializeRepositories();
    _loadData();
    _loadConnectedUser();
    _initFcmListener();
    _evaluateWelcomeBlockOncePerDay();
  }

  void _initializeRepositories() {
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );

    _apiClient = apiClient;
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

  // Fonction pour afficher le modal de succès d'inscription
  void _showInscriptionSuccess(String message, String formationTitle) {
    setState(() {
      _inscriptionSuccessMessage = message;
      _inscriptionFormationTitle = formationTitle;
      _showInscriptionSuccessModal = true;
    });
  }

  // Fonction pour fermer le modal de succès d'inscription
  void _closeInscriptionSuccessModal() {
    setState(() {
      _showInscriptionSuccessModal = false;
      _inscriptionSuccessMessage = '';
      _inscriptionFormationTitle = '';
    });
  }

  // Fonction pour naviguer vers le catalogue après inscription
  void _navigateToCatalogueAfterInscription() {
    _closeInscriptionSuccessModal();
    // Navigation vers le catalogue
    Navigator.pushReplacementNamed(context, RouteConstants.dashboard);
  }

  // Pré-charge la valeur locale pour un affichage instantané au démarrage
  Future<void> _primeStreakFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final local = prefs.getInt('login_streak');
      if (local != null) {
        if (mounted) {
          setState(() {
            _loginStreak = local;
          });
        }
      }
    } catch (_) {
      // ignore
    }
  }

  // Afficher le bloc de bienvenue uniquement une fois par jour
  Future<void> _evaluateWelcomeBlockOncePerDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastShown = prefs.getString('lastWelcomeShownDate');
      final now = DateTime.now();
      final today =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      if (lastShown == today) {
        if (mounted) setState(() => _showWelcomeBlock = false);
      } else {
        // Marquer comme montré pour aujourd'hui et activer l'affichage
        await prefs.setString('lastWelcomeShownDate', today);
        if (mounted) setState(() => _showWelcomeBlock = true);
      }
    } catch (_) {
      // En cas d'erreur de stockage, on affiche par défaut
      if (mounted) setState(() => _showWelcomeBlock = true);
    }
  }

  Future<void> _loadConnectedUser() async {
    try {
      final user = await _authRepository.getMe();

      // 1) Préférer la valeur backend si disponible via un appel léger au profil
      // 2) Repli: SharedPreferences
      int loginStreak = await _fetchLoginStreakFromBackend().catchError((
        _,
      ) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          return prefs.getInt('login_streak') ?? 0;
        } catch (_) {
          return 0;
        }
      });

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

  // Récupère login_streak depuis /stagiaire/profile, sinon lance une erreur
  Future<int> _fetchLoginStreakFromBackend() async {
    try {
      // L'ApiClient injecte déjà l'Authorization via les interceptors
      final response = await _apiClient.get('/stagiaire/profile');

      final data = response.data;
      if (data is Map) {
        // Plusieurs structures possibles: { stagiaire: { login_streak: N } } ou { login_streak: N }
        final stagiaire = data['stagiaire'];
        final dynamic val =
            stagiaire is Map ? stagiaire['login_streak'] : data['login_streak'];
        int parsed;
        if (val is int) {
          parsed = val;
        } else if (val is String) {
          parsed = int.tryParse(val) ?? 0;
        } else {
          parsed = 0;
        }
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('login_streak', parsed);
        } catch (_) {
          // ignore local persistence errors
        }
        return parsed;
      }
      // Si pas trouvé, lever pour déclencher le repli
      throw Exception('login_streak absent');
    } catch (e) {
      // Propager pour utiliser le repli SharedPreferences
      rethrow;
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
                        if (_showWelcomeBlock)
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
                            onInscriptionSuccess:
                                _showInscriptionSuccess, // Passer la callback
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
                        const SliverToBoxAdapter(child: HowToPlay()),
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
                            // Text(
                            //   '7 jours',
                            //   style: TextStyle(
                            //     color: kOrangeDark,
                            //     fontWeight: FontWeight.w600,
                            //   ),
                            // ),
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
                      // const SizedBox(height: 12),
                      // Text(
                      //   'Continuez comme ça pour débloquer des récompenses 🎉',
                      //   textAlign: TextAlign.center,
                      //   style: theme.textTheme.bodyMedium,
                      // ),
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
                          // OutlinedButton(
                          //   onPressed: _closeStreakModal,
                          //   child: const Text('Fermer'),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Modal de succès pour l'inscription aux formations
        if (_showInscriptionSuccessModal)
          Positioned.fill(
            child: _InscriptionSuccessModal(
              isOpen: _showInscriptionSuccessModal,
              onClose: _closeInscriptionSuccessModal,
              onContinue: _navigateToCatalogueAfterInscription,
              message: _inscriptionSuccessMessage,
              formationTitle: _inscriptionFormationTitle,
            ),
          ),
      ],
    );
  }

  // Le reste du code reste inchangé...
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

    // Filtrage et organisation des contacts par type dans l'ordre demandé
    final orderedContacts = <Contact>[];

    // 1. FORMATEURS
    final formateurs =
        _contacts
            .where(
              (contact) => contact.type.toLowerCase().contains('formateur'),
            )
            .toList();
    orderedContacts.addAll(formateurs);

    // 2. PÔLE SAV
    final poleSav =
        _contacts
            .where(
              (contact) =>
                  contact.type.toLowerCase().contains('sav') ||
                  contact.type.toLowerCase().contains('pole_sav'),
            )
            .toList();
    orderedContacts.addAll(poleSav);

    // 3. COMMERCIAUX
    final commerciaux =
        _contacts
            .where(
              (contact) => contact.type.toLowerCase().contains('commercial'),
            )
            .toList();
    orderedContacts.addAll(commerciaux);

    // 4. PÔLE RELATION CLIENTS
    final poleRelation =
        _contacts
            .where(
              (contact) =>
                  contact.type.toLowerCase().contains('relation') ||
                  contact.type.toLowerCase().contains('pole_relation'),
            )
            .toList();
    orderedContacts.addAll(poleRelation);

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

// Composant Modal pour le succès de l'inscription
class _InscriptionSuccessModal extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final VoidCallback onContinue;
  final String message;
  final String formationTitle;

  const _InscriptionSuccessModal({
    required this.isOpen,
    required this.onClose,
    required this.onContinue,
    required this.message,
    required this.formationTitle,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    return Material(
      color: Colors.black54,
      child: GestureDetector(
        onTap: onClose, // Fermer en tapant à l'extérieur
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Empêcher la fermeture en tapant à l'intérieur
            child: Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header avec icône et titre
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icône de succès
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9C4),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              size: 24,
                              color: Color(0xFFF57C00),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Titre
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Demande d\'inscription envoyée avec succès !',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Bouton fermeture aligné à droite
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    onPressed: onClose,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Contenu principal
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Votre demande d\'inscription a été envoyée pour la formation :',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Nom de la formation
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Text(
                              formationTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Message de confirmation
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFECB3),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Color(0xFFF57C00),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF7D6608),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Bouton d'action principal
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.explore_outlined, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Continuer à explorer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Bouton secondaire
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: onClose,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Rester sur cette page',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
