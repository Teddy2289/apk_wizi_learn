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
import 'package:wizi_learn/features/auth/presentation/widgets/welcom_bannery.dart';
import 'package:wizi_learn/features/home/presentation/widgets/how_to_play.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wizi_learn/core/services/quiz_persistence_service.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/resume_quiz_dialog.dart';
import 'package:wizi_learn/features/auth/presentation/pages/quiz_session_page.dart';
import 'package:wizi_learn/features/auth/data/models/quiz_model.dart';

import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository.dart';

// Nouvelle palette de couleurs harmonieuse
const Color kPrimaryBlue = Color(0xFF3D9BE9);
// #df7609
const Color kpOrange = Color(0xFFDF7609);
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
  int _loginStreak = 0;
  bool _showStreakModal = false;
  bool _hideStreakFor7Days = false;
  bool _showWelcomeBlock = false;

  bool _showInscriptionSuccessModal = false;
  String _inscriptionSuccessMessage = '';
  String _inscriptionFormationTitle = '';
  
  // Resume quiz functionality
  bool _showResumeQuizDialog = false;
  Map<String, dynamic>? _unfinishedQuizData;

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
    _checkForUnfinishedQuiz();
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

  void _showInscriptionSuccess(String message, String formationTitle) {
    setState(() {
      _inscriptionSuccessMessage = message;
      _inscriptionFormationTitle = formationTitle;
      _showInscriptionSuccessModal = true;
    });
  }

  void _closeInscriptionSuccessModal() {
    setState(() {
      _showInscriptionSuccessModal = false;
      _inscriptionSuccessMessage = '';
      _inscriptionFormationTitle = '';
    });
  }

  void _navigateToCatalogueAfterInscription() {
    _closeInscriptionSuccessModal();
    Navigator.pushReplacementNamed(context, RouteConstants.dashboard);
  }

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
    } catch (_) {}
  }

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
        await prefs.setString('lastWelcomeShownDate', today);
        if (mounted) setState(() => _showWelcomeBlock = true);
      }
    } catch (_) {
      if (mounted) setState(() => _showWelcomeBlock = true);
    }
  }

  Future<void> _loadConnectedUser() async {
    try {
      final user = await _authRepository.getMe();
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
        await _checkAndShowStreakModal();
      }
    } catch (e) {
      debugPrint('Erreur en chargeant l\'utilisateur connecté: $e');
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  Future<int> _fetchLoginStreakFromBackend() async {
    try {
      final response = await _apiClient.get('/stagiaire/profile');
      final data = response.data;
      if (data is Map) {
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
        } catch (_) {}
        return parsed;
      }
      throw Exception('login_streak absent');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _checkAndShowStreakModal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastShown = prefs.getString('lastStreakModalDate');
      final hideUntil = prefs.getString('streakModalHideUntil');
      if (hideUntil != null) {
        try {
          final hideDate = DateTime.parse(hideUntil);
          final todayDate = DateTime.now();
          if (!todayDate.isAfter(hideDate)) {
            return;
          }
        } catch (_) {}
      }
      final now = DateTime.now();
      final today =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      if (lastShown == today) return;
      if (_loginStreak > 0) {
        if (mounted) setState(() => _showStreakModal = true);
      }
    } catch (e) {}
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
        await prefs.remove('streakModalHideUntil');
      }
    } catch (e) {}
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
            backgroundColor: kErrorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkForUnfinishedQuiz() async {
    try {
      final persistenceService = QuizPersistenceService();
      final unfinishedQuiz = await persistenceService.getLastUnfinishedQuiz();
      
      if (unfinishedQuiz != null && mounted) {
        // Show dialog after a short delay to avoid conflicting with other modals
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          setState(() {
            _unfinishedQuizData = unfinishedQuiz;
            _showResumeQuizDialog = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking for unfinished quiz: $e');
    }
  }

  void _handleResumeQuiz() {
    if (_unfinishedQuizData != null) {
      setState(() => _showResumeQuizDialog = false);
      
      // Navigate to quiz session page
      // Note: This navigation assumes the Quiz and Questions data can be reconstructed
      // In a real scenario, you'd fetch the full quiz data from the API
      Navigator.of(context).pushNamed(
        RouteConstants.quiz,
        arguments: {
          'quizId': _unfinishedQuizData!['quizId'],
          'resume': true,
        },
      );
    }
  }

  void _handleDismissQuiz() async {
    if (_unfinishedQuizData != null) {
      final quizId = _unfinishedQuizData!['quizId'] as String;
      final persistenceService = QuizPersistenceService();
      await persistenceService.clearSession(quizId);
      
      if (mounted) {
        setState(() {
          _showResumeQuizDialog = false;
          _unfinishedQuizData = null;
        });
      }
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
          backgroundColor: kNeutralGrey,
          body:
              (_isLoading || _isLoadingUser)
                  ? Center(
                    child: CircularProgressIndicator(color: kPrimaryBlue),
                  )
                  : RefreshIndicator(
                    onRefresh: _loadData,
                    color: kPrimaryBlue,
                    child: CustomScrollView(
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: WelcomeBanner(
                              showDismissOption: true,
                              variant: 'default',
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        if (_showWelcomeBlock)
                          SliverToBoxAdapter(
                            child: _buildSectionTitle(
                              context,
                              title: 'Comment participer ?',
                              icon: LucideIcons.gamepad2,
                            ),
                          ),
                        SliverToBoxAdapter(child: const HowToPlay()),
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        SliverToBoxAdapter(
                          child: _buildSectionTitle(
                          context,
                          title: 'Boostez vos compétences dès aujourd\'hui !',
                          icon: LucideIcons.bookOpen,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            'Des formations certifiantes adaptées à vos besoins.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: kNeutralGreyDark,
                              fontWeight: FontWeight.w600,
                              ),
                          ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: RandomFormationsWidget(
                            formations: _randomFormations,
                            onRefresh: _loadData,
                            onInscriptionSuccess: _showInscriptionSuccess,
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
                      ],
                    ),
                  ),
        ),
        if (_showStreakModal)
          Positioned.fill(
            child: Material(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kNeutralWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimaryBlueLight, kAccentPurpleLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: kPrimaryBlue.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Série de connexions',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: kPrimaryBlueDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [kPrimaryBlue, kAccentPurple],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimaryBlue.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.local_fire_department_rounded,
                                color: kNeutralWhite,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$_loginStreak jour${_loginStreak > 1 ? 's' : ''} d\'affilée',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: kPrimaryBlueDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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
                            activeColor: kPrimaryBlue,
                          ),
                          Expanded(
                            child: Text(
                              'Ne plus montrer pendant 7 jours',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: kNeutralGreyDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryBlue,
                            foregroundColor: kNeutralWhite,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed: _closeStreakModal,
                          child: Text(
                            'Continuer',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
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
        if (_showResumeQuizDialog && _unfinishedQuizData != null)
          Positioned.fill(
            child: Material(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: ResumeQuizDialog(
                  quizData: _unfinishedQuizData!,
                  onResume: _handleResumeQuiz,
                  onDismiss: _handleDismissQuiz,
                ),
              ),
            ),
          ),
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
            colors: [kPrimaryBlueLight, kAccentPurpleLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isTablet ? 60 : 48,
              height: isTablet ? 60 : 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryBlue, kAccentPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.megaphone,
                color: kNeutralWhite,
                size: isTablet ? 28 : 22,
              ),
            ),
            const SizedBox(width: 16),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kpOrange, kpOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: kNeutralWhite, size: 20),
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
                    color: kpOrange,
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kpOrange, kpOrange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: kNeutralWhite, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kpOrange,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                foregroundColor: kNeutralWhite,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kNeutralWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kPrimaryBlue.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Aucun contact disponible',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: kNeutralGreyDark),
              ),
            ),
          ),
        ),
      );
    }

    final orderedContacts = <Contact>[];
    final formateurs =
        _contacts
            .where(
              (contact) => contact.type.toLowerCase().contains('formateur'),
            )
            .toList();
    orderedContacts.addAll(formateurs);

    final poleSav =
        _contacts
            .where(
              (contact) =>
                  contact.type.toLowerCase().contains('sav') ||
                  contact.type.toLowerCase().contains('pole_sav'),
            )
            .firstOrNull;

    if (poleSav != null) {
      orderedContacts.add(poleSav);
    }

    final commerciaux =
        _contacts
            .where(
              (contact) => contact.type.toLowerCase().contains('commercial'),
            )
            .toList();
    orderedContacts.addAll(commerciaux);

    final poleRelation =
        _contacts
            .where(
              (contact) =>
                  contact.type.toLowerCase().contains('relation') ||
                  contact.type.toLowerCase().contains('pole_relation'),
            )
            .toList();
    orderedContacts.addAll(poleRelation);

    final screenWidth = MediaQuery.of(context).size.width;
    final viewportFraction = isTablet ? 0.6 : 0.95;
    final carouselHeight = isTablet ? 170.0 : 140.0;

    if (!isTablet) {
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

  Widget _buildFeatureChip(String text, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14 : 12,
        vertical: isTablet ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: kNeutralWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryBlue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isTablet ? 12 : 10,
          fontWeight: FontWeight.w600,
          color: kPrimaryBlueDark,
        ),
      ),
    );
  }
}

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
        onTap: onClose,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Dialog(
              backgroundColor: kNeutralWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [kSuccessGreen, kPrimaryBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 28,
                              color: kNeutralWhite,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Demande d\'inscription envoyée !',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryBlueDark,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: kNeutralGrey,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: kNeutralGreyDark,
                              ),
                            ),
                            onPressed: onClose,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Votre demande d\'inscription a été envoyée pour la formation :',
                            style: TextStyle(
                              color: kNeutralGreyDark,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kPrimaryBlueLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: kPrimaryBlue.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              formationTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: kPrimaryBlueDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kSuccessGreenLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: kSuccessGreen.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 24,
                                  color: kSuccessGreenDark,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  message,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: kSuccessGreenDark,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryBlue,
                            foregroundColor: kNeutralWhite,
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
                              color: kNeutralGreyDark,
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
