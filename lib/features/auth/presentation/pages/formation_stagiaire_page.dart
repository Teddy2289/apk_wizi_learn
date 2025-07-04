import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/constants/route_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:wizi_learn/features/auth/data/models/formation_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/auth_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/formation_repository.dart';
import 'package:intl/intl.dart';
import 'package:wizi_learn/features/auth/presentation/pages/contact_page.dart';
import 'package:wizi_learn/features/auth/data/models/contact_model.dart';

class FormationStagiairePage extends StatefulWidget {
  const FormationStagiairePage({super.key});

  @override
  State<FormationStagiairePage> createState() => _FormationStagiairePageState();
}

class _FormationStagiairePageState extends State<FormationStagiairePage> {
  late final FormationRepository _repository;
  late final AuthRepository _authRepository;
  Future<List<Formation>> _futureFormations = Future.value([]);
  final Map<int, bool> _expandedFormations = {};
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  // Styles par catégorie
  final Map<String, Map<String, dynamic>> _categoryStyles = {
    'Bureautique': {
      'icon': Icons.computer,
      'color': const Color(0xFF3D9BE9),
      'lightColor': const Color(0xFFE3F2FD),
    },
    'Langues': {
      'icon': Icons.language,
      'color': const Color(0xFFA55E6E),
      'lightColor': const Color(0xFFFCE4EC),
    },
    'Internet': {
      'icon': Icons.public,
      'color': const Color(0xFFFFC533),
      'lightColor': const Color(0xFFFFF8E1),
    },
    'Création': {
      'icon': Icons.brush,
      'color': const Color(0xFF9392BE),
      'lightColor': const Color(0xFFEDE7F6),
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeRepositories();
    _loadFormationsForConnectedStagiaire();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= 400 && !_showBackToTopButton) {
      setState(() => _showBackToTopButton = true);
    } else if (_scrollController.offset < 400 && _showBackToTopButton) {
      setState(() => _showBackToTopButton = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _initializeRepositories() {
    final dio = Dio();
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(dio: dio, storage: storage);

    _repository = FormationRepository(apiClient: apiClient);
    _authRepository = AuthRepository(
      remoteDataSource: AuthRemoteDataSourceImpl(
        apiClient: apiClient,
        storage: storage,
      ),
      storage: storage,
    );
  }

  Future<void> _loadFormationsForConnectedStagiaire() async {
    try {
      final user = await _authRepository.getMe();
      final connectedStagiaireId = user.stagiaire?.id;

      if (connectedStagiaireId == null) {
        setState(() => _futureFormations = Future.value([]));
        return;
      }

      setState(() {
        _futureFormations = _repository.getCatalogueFormations(
          stagiaireId: connectedStagiaireId,
        );
      });
    } catch (e) {
      debugPrint('Erreur chargement formations: $e');
      setState(() => _futureFormations = Future.error(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Formations'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              () => Navigator.pushReplacementNamed(
                context,
                RouteConstants.dashboard,
              ),
        ),
        backgroundColor:
            isDarkMode ? theme.appBarTheme.backgroundColor : Colors.white,
        elevation: 1,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      ),
      body: _buildBody(theme),
      floatingActionButton:
          _showBackToTopButton
              ? FloatingActionButton(
                onPressed: _scrollToTop,
                mini: true,
                backgroundColor: theme.colorScheme.primary,
                child: Icon(
                  Icons.arrow_upward,
                  color: theme.colorScheme.onPrimary,
                ),
              )
              : null,
    );
  }

  Widget _buildBody(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadFormationsForConnectedStagiaire,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Mes formations en cours',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Retrouvez ici toutes vos formations actives',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            FutureBuilder<List<Formation>>(
              future: _futureFormations,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(child: _buildErrorState(theme));
                }

                final formations = snapshot.data ?? [];
                if (formations.isEmpty) {
                  return SliverFillRemaining(child: _buildEmptyState(theme));
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final formation = formations[index];
                    final category = formation.category.categorie;
                    final styles =
                        _categoryStyles[category] ??
                        {
                          'icon': Icons.school,
                          'color': Colors.grey,
                          'lightColor': Colors.grey.shade200,
                        };

                    return _buildFormationCard(formation, styles, theme);
                  }, childCount: formations.length),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text('Erreur de chargement', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Nous n\'avons pas pu charger vos formations. Veuillez réessayer.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loadFormationsForConnectedStagiaire,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: const Text('Réessayer'),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.school_outlined,
          size: 48,
          color: theme.colorScheme.primary.withOpacity(0.5),
        ),
        const SizedBox(height: 16),
        Text('Aucune formation', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Vous n\'êtes actuellement inscrit à aucune formation.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            // Naviguer vers le catalogue des formations
          },
          child: const Text('Découvrir les formations'),
        ),
      ],
    );
  }

  Widget _buildFormationCard(
    Formation formation,
    Map<String, dynamic> styles,
    ThemeData theme,
  ) {
    final isExpanded = _expandedFormations[formation.id] ?? false;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkMode ? theme.cardTheme.color : styles['lightColor'],
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _expandedFormations[formation.id] = !isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: styles['color'].withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(styles['icon'], color: styles['color']),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formation.titre.toUpperCase(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formation.category.categorie,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: styles['color'],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: styles['color'],
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 16),
                Divider(color: theme.dividerColor.withOpacity(0.3)),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.schedule,
                  'Durée: ${formation.duree} heures',
                  theme,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Début de formation: ${formation.dateDebut ?? "-"}',
                  theme,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_month,
                  'Fin de formation: ${formation.dateFin ?? "-"}',
                  theme,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.euro_symbol,
                  'Prix: ${NumberFormat('#,##0', 'fr_FR').format(formation.tarif)} €',
                  theme,
                ),
                if (formation.certification != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.verified,
                    formation.certification ?? 'Formation certifiante',
                    theme,
                    color: Colors.green,
                  ),
                ],
                const SizedBox(height: 8),
                if (formation.formateur != null) ...[
                  GestureDetector(
                    // onTap: () {
                    //   Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //       builder: (context) => ContactPage(
                    //         contacts: [
                    //           Contact(
                    //             nom: formation.formateur!.user!.nom,
                    //             prenom: formation.formateur!.prenom,
                    //             email: formation.formateur!.user!.email,
                    //             telephone: formation.formateur!.telephone,
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   );
                    // },
                    child: _buildInfoRow(
                      Icons.person,
                      'Formateur: ${formation.formateur!.prenom} ${formation.formateur!.nom.toUpperCase()}',
                      theme,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                Text(
                  'Description',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formation.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    ThemeData theme, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
