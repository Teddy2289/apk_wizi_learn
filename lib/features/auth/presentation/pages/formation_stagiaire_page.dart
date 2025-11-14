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
import 'package:wizi_learn/features/auth/presentation/widgets/custom_scaffold.dart';
import 'package:flutter_html/flutter_html.dart';

class FormationStagiairePage extends StatefulWidget {
  const FormationStagiairePage({super.key});

  @override
  State<FormationStagiairePage> createState() => _FormationStagiairePageState();
}

class _FormationStagiairePageState extends State<FormationStagiairePage> {
  late final FormationRepository _repository;
  late final AuthRepository _authRepository;
  List<Formation> _formations = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Map<int, bool> _expandedFormations = {};
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;
  bool _fromNotification = false;

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
    'IA': {
      'icon': Icons.psychology,
      'color': const Color(0xFFABDA96),
      'lightColor': const Color.fromARGB(255, 241, 255, 225),
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args['fromNotification'] == true) {
        setState(() => _fromNotification = true);
      }
    });
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
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = await _authRepository.getMe();
      final connectedStagiaireId = user.stagiaire?.id;

      if (connectedStagiaireId == null) {
        setState(() {
          _isLoading = false;
          _formations = [];
        });
        return;
      }

      final formations = await _repository.getCatalogueFormations(
        stagiaireId: connectedStagiaireId,
      );

      // Filtre les formations invalides
      final validFormations =
          formations
              .where((f) => f.titre.isNotEmpty && f.titre != 'null')
              .toList();

      setState(() {
        _formations = validFormations.cast<Formation>();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement formations: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement des formations';
        _formations = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return _fromNotification
        ? CustomScaffold(
          body: _buildBody(theme),
          currentIndex: 1,
          onTabSelected: (index) {
            Navigator.pushReplacementNamed(
              context,
              RouteConstants.dashboard,
              arguments: index,
            );
          },
          showBanner: true,
        )
        : Scaffold(
          appBar: AppBar(
            title: const Text('Mes Formations'),
            centerTitle: true,
            /*leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed:
                  () => Navigator.pushReplacementNamed(
                    context,
                    RouteConstants.dashboard,
                  ),
            ),*/
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
            _isLoading
                ? SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                )
                : _errorMessage != null
                ? SliverFillRemaining(child: _buildErrorState(theme))
                : _formations.isEmpty
                ? SliverFillRemaining(child: _buildEmptyState(theme))
                : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final formation = _formations[index];
                    final category = formation.category.categorie;
                    final styles =
                        _categoryStyles[category] ??
                        {
                          'icon': Icons.school,
                          'color': Colors.grey,
                          'lightColor': Colors.grey.shade200,
                        };

                    return _buildFormationCard(formation, styles, theme);
                  }, childCount: _formations.length),
                ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
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
        onTap:
            () =>
                setState(() => _expandedFormations[formation.id] = !isExpanded),
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
                          (formation.category.titre).toUpperCase(),
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
                  'Début: ${_formatDate(formation.dateDebut)}',
                  theme,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_month,
                  'Fin: ${_formatDate(formation.dateFin)}',
                  theme,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.euro_symbol,
                  'Prix: ${NumberFormat('#,##0', 'fr_FR').format(formation.tarif)} €',
                  theme,
                ),
                // if (formation.certification != null &&
                //     formation.certification!.isNotEmpty) ...[
                //   const SizedBox(height: 8),
                //   _buildInfoRow(
                //     Icons.verified,
                //     formation.certification!,
                //     theme,
                //     color: Colors.green,
                //   ),
                // ],
                if (formation.formateur != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.person,
                    'Formateur: ${formation.formateur!.prenom} ${formation.formateur!.nom.toUpperCase()}',
                    theme,
                    color: Colors.blue,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Description',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Html(
                    data: formation.description,
                    style: {
                      'body': Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(14),
                        color: Colors.grey.shade700,
                      ),
                      'ul': Style(
                        margin: Margins.only(bottom: 8),
                        padding: HtmlPaddings.zero,
                      ),
                      'li': Style(
                        margin: Margins.only(bottom: 4),
                        padding: HtmlPaddings.zero,
                      ),
                      'p': Style(
                        margin: Margins.only(bottom: 8),
                        padding: HtmlPaddings.zero,
                      ),
                      'strong': Style(fontWeight: FontWeight.bold),
                      'em': Style(fontStyle: FontStyle.italic),
                    },
                  ),
                ),
              ],
            ],
          ),
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
        Text(
          _errorMessage ?? 'Erreur inconnue',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
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
        Text(
          'Vous n\'êtes actuellement inscrit à aucune formation.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {},
          child: const Text('Découvrir les formations'),
        ),
      ],
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

  String _formatDate(String? date) {
    if (date == null || date.isEmpty || date.toLowerCase() == 'null') {
      return '-';
    }
    try {
      final d = DateTime.parse(date);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return date;
    }
  }

  //
}
