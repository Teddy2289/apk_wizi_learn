import 'package:flutter/material.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:wizi_learn/features/auth/data/models/stats_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/auth_repository.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

class GlobalRankingWidget extends StatefulWidget {
  final List<GlobalRanking> rankings;

  const GlobalRankingWidget({super.key, required this.rankings});

  @override
  State<GlobalRankingWidget> createState() => _GlobalRankingWidgetState();
}

class _GlobalRankingWidgetState extends State<GlobalRankingWidget> {
  late final AuthRepository _authRepository;
  int? _connectedStagiaireId;
  bool _isLoadingUser = true;
  // Afficher le classement en mode liste (sans podium)
  bool _showList = false;

  @override
  void initState() {
    super.initState();
    _initializeRepositories();
    _loadConnectedUser();
  }

  void _initializeRepositories() {
    final dio = Dio();
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(dio: dio, storage: storage);

    _authRepository = AuthRepository(
      remoteDataSource: AuthRemoteDataSourceImpl(
        apiClient: apiClient,
        storage: storage,
      ),
      storage: storage,
    );
  }

  Future<void> _loadConnectedUser() async {
    try {
      final user = await _authRepository.getMe();
      setState(() {
        _connectedStagiaireId = user.stagiaire?.id;
        debugPrint('Utilisateur connecté: ${user.stagiaire?.id}');
        _isLoadingUser = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement utilisateur: $e');
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    if (_isLoadingUser) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.rankings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'Aucun classement disponible',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Séparation top 3 et reste
    final podium = widget.rankings.take(3).toList();
    final rest = widget.rankings.length > 3 ? widget.rankings.sublist(3) : [];
    final myIndex = widget.rankings.indexWhere(
      (r) => int.tryParse(r.stagiaire.id.toString()) == _connectedStagiaireId,
    );
    final isCurrentUserInRest = myIndex >= 3;

    // Responsive layout: single column on small screens, two-column on wider screens
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;

    // If user requested list view, render full list (no podium)
    if (_showList) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.leaderboard,
                    color: Theme.of(context).primaryColor,
                    size: isSmallScreen ? 24 : 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Classement Global',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 18 : 22,
                      ),
                    ),
                  ),
                  // Switch pour basculer l'affichage
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_showList ? 'Liste' : 'Podium'),
                      const SizedBox(width: 8),
                      Switch(
                        value: _showList,
                        onChanged: (v) => setState(() => _showList = v),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildHeader(context, isSmallScreen),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.rankings.length,
                separatorBuilder: (_, __) => const Divider(height: 8),
                itemBuilder: (_, index) {
                  final ranking = widget.rankings[index];
                  final isCurrentUser =
                      int.tryParse(ranking.stagiaire.id.toString()) ==
                      _connectedStagiaireId;
                  return _buildRankingItem(
                    context,
                    ranking,
                    isSmallScreen,
                    isCurrentUser: isCurrentUser,
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    if (!isWide) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.leaderboard,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Classement Global',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 18 : 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Podium
              _buildPodium(context, podium, isSmallScreen),
              const SizedBox(height: 16),
              // Liste classique
              if (rest.isNotEmpty) ...[
                _buildHeader(context, isSmallScreen),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rest.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (_, index) {
                    final ranking = rest[index];
                    final isCurrentUser =
                        int.tryParse(ranking.stagiaire.id.toString()) ==
                        _connectedStagiaireId;
                    return _buildRankingItem(
                      context,
                      ranking,
                      isSmallScreen,
                      isCurrentUser: isCurrentUser,
                    );
                  },
                ),
              ],
              // Si l'utilisateur n'est pas dans le top, l'afficher en bas
              if (isCurrentUserInRest)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildRankingItem(
                    context,
                    widget.rankings[myIndex],
                    isSmallScreen,
                    isCurrentUser: true,
                    highlight: true,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Wide layout: podium on left, list on right
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: title + podium
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.leaderboard,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Classement Global',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    // Switch pour basculer l'affichage
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_showList ? 'Liste' : 'Podium'),
                        const SizedBox(width: 8),
                        Switch(
                          value: _showList,
                          onChanged: (v) => setState(() => _showList = v),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPodium(context, podium, false),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right: header + list
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, false),
                const SizedBox(height: 8),
                Expanded(
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child:
                          rest.isEmpty
                              ? Center(
                                child: Text('Aucun classement supplémentaire'),
                              )
                              : ListView.separated(
                                itemCount: rest.length,
                                separatorBuilder:
                                    (_, __) => const Divider(height: 8),
                                itemBuilder: (_, index) {
                                  final ranking = rest[index];
                                  final isCurrentUser =
                                      int.tryParse(
                                        ranking.stagiaire.id.toString(),
                                      ) ==
                                      _connectedStagiaireId;
                                  return _buildRankingItem(
                                    context,
                                    ranking,
                                    false,
                                    isCurrentUser: isCurrentUser,
                                  );
                                },
                              ),
                    ),
                  ),
                ),
                if (isCurrentUserInRest)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildRankingItem(
                      context,
                      widget.rankings[myIndex],
                      false,
                      isCurrentUser: true,
                      highlight: true,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(
    BuildContext context,
    List<GlobalRanking> podium,
    bool isSmallScreen,
  ) {
    // Ordre d'affichage : 2e, 1er, 3e
    final List<int> order = [1, 0, 2];
    final double base = isSmallScreen ? 50 : 70;
    final List<double> heights = [base, base + 40, base - 15];
    final List<double> sizes = [
      isSmallScreen ? 40 : 56,
      isSmallScreen ? 56 : 72,
      isSmallScreen ? 32 : 48,
    ];
    final List<Color> colors = [
      const Color(0xFFC0C0C0), // Argent
      const Color(0xFFFFD700), // Or
      const Color(0xFFCD7F32), // Bronze
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.05),
            Theme.of(context).primaryColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Titre du podium
          Text(
            '🏆 PODIUM 🏆',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          // Podium
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final idx = order[i];
              if (idx >= podium.length) {
                return Expanded(child: const SizedBox());
              }
              final ranking = podium[idx];
              final isCurrentUser =
                  int.tryParse(ranking.stagiaire.id.toString()) ==
                  _connectedStagiaireId;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Badge de position
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors[i].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors[i], width: 1.5),
                      ),
                      child: Text(
                        '${idx + 1}${idx == 0 ? 'er' : 'e'}',
                        style: TextStyle(
                          color: colors[i],
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ),
                    // Avatar avec fond
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: heights[i],
                          width: sizes[i],
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colors[i].withOpacity(0.3),
                                colors[i].withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colors[i], width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: colors[i].withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: (sizes[i] - 8) / 2,
                          backgroundImage:
                              ranking.stagiaire.image.isNotEmpty
                                  ? NetworkImage(
                                    '${AppConstants.baseUrlImg}/${ranking.stagiaire.image}',
                                  )
                                  : null,
                          backgroundColor: Colors.white,
                          child:
                              ranking.stagiaire.image.isEmpty
                                  ? Icon(
                                    Icons.person,
                                    size: sizes[i] / 3,
                                    color: Colors.grey.shade400,
                                  )
                                  : null,
                        ),
                        if (isCurrentUser)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Nom du participant
                    Text(
                      '${ranking.stagiaire.prenom} ${ranking.stagiaire.nom.toUpperCase()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            isCurrentUser
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).colorScheme.onSurface,
                        fontSize: isSmallScreen ? 13 : 15,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Formateurs
                    if (ranking.formateurs.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          ranking.formateurs
                              .map((f) => '${f.prenom} ${f.nom.toUpperCase()}')
                              .join(', '),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 9 : 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Points
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${ranking.totalPoints} pts',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 11 : 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: isSmallScreen ? 36 : 48,
            child: const Text('Rang', style: _headerTextStyle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Participant', style: _headerTextStyle),
                Text(
                  'Formateur(s)',
                  style: _headerTextStyle.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!isSmallScreen)
            Expanded(
              child: Text(
                'Quiz joués',
                style: _headerTextStyle,
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: Text(
              'Points',
              style: _headerTextStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem(
    BuildContext context,
    GlobalRanking ranking,
    bool isSmallScreen, {
    bool isCurrentUser = false,
    bool highlight = false,
  }) {
    return Container(
      margin: highlight ? const EdgeInsets.symmetric(vertical: 8) : null,
      decoration: BoxDecoration(
        color:
            isCurrentUser
                ? Theme.of(context).primaryColor.withOpacity(0.08)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border:
            highlight
                ? Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  width: 2,
                )
                : null,
        boxShadow:
            highlight
                ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : [],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            // Rang
            SizedBox(
              width: isSmallScreen ? 36 : 48,
              child: Center(
                child: Container(
                  width: isSmallScreen ? 28 : 32,
                  height: isSmallScreen ? 28 : 32,
                  decoration: BoxDecoration(
                    color: _getRankColor(context, ranking.rang),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${ranking.rang}',
                      style: TextStyle(
                        color: _getRankTextColor(context, ranking.rang),
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Participant et Formateurs
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ligne du stagiaire
                  Row(
                    children: [
                      CircleAvatar(
                        radius: isSmallScreen ? 20 : 24,
                        backgroundImage:
                            ranking.stagiaire.image.isNotEmpty
                                ? NetworkImage(
                                  '${AppConstants.baseUrlImg}/${ranking.stagiaire.image}',
                                )
                                : null,
                        backgroundColor: Colors.white,
                        child:
                            ranking.stagiaire.image.isEmpty
                                ? Icon(
                                  Icons.person,
                                  size: isSmallScreen ? 16 : 20,
                                  color: Colors.grey.shade400,
                                )
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ranking.stagiaire.prenom} ${ranking.stagiaire.nom.toUpperCase()}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 14 : 16,
                                color:
                                    isCurrentUser
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Formateurs
                            if (ranking.formateurs.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Formateur: ${ranking.formateurs.map((f) => '${f.prenom} ${f.nom.toUpperCase()}').join(', ')}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quiz joués (seulement sur grand écran)
            if (!isSmallScreen)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${ranking.quizCount}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'quiz',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Points
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.1),
                        Theme.of(context).primaryColor.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${ranking.totalPoints}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                      Text(
                        'points',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.8),
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(BuildContext context, int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.withOpacity(0.3);
      case 2:
        return Colors.grey.withOpacity(0.3);
      case 3:
        return Colors.orange.withOpacity(0.3);
      default:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  Color _getRankTextColor(BuildContext context, int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade800;
      case 2:
        return Colors.grey.shade800;
      case 3:
        return Colors.orange.shade800;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }
}

const _headerTextStyle = TextStyle(
  fontWeight: FontWeight.w600,
  color: Colors.grey,
  fontSize: 12,
  letterSpacing: 0.5,
);
