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

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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

            if (widget.rankings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
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
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  _buildHeader(context, isSmallScreen),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.rankings.length,
                    separatorBuilder: (_, __) => const Divider(height: 8),
                    itemBuilder:
                        (_, index) => _buildRankingItem(
                          context,
                          widget.rankings[index],
                          isSmallScreen,
                        ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
            child: Text('Participant', style: _headerTextStyle),
          ),
          if (!isSmallScreen)
            Expanded(
              child: Text(
                'Quiz complétés',
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
    bool isSmallScreen,
  ) {
    // Conversion sécurisée pour la comparaison
    final rankingId = int.tryParse(ranking.stagiaire.id.toString());
    final isCurrentUser = rankingId == _connectedStagiaireId;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        // Action lorsqu'on clique sur un participant
      },
      child: Container(
        decoration: BoxDecoration(
          color:
              isCurrentUser
                  ? Theme.of(context).primaryColor.withOpacity(0.05)
                  : Colors.transparent,
          border:
              isCurrentUser
                  ? Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    width: 1,
                  )
                  : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              // Rang avec badge coloré
              SizedBox(
                width: isSmallScreen ? 36 : 48,
                child: Center(
                  child: isCurrentUser
                      ? Container(
                    width: isSmallScreen ? 28 : 32,
                    height: isSmallScreen ? 28 : 32,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.green,
                      size: isSmallScreen ? 16 : 18,
                    ),
                  )
                      : Container(
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
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Photo + Nom
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: isSmallScreen ? 20 : 24,
                          backgroundImage: NetworkImage(
                            '${AppConstants.baseUrlImg}/${ranking.stagiaire.image}',
                          ),
                          onBackgroundImageError: (_, __) =>
                              Icon(Icons.person, size: isSmallScreen ? 20 : 24),
                        ),
                        if (isCurrentUser)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ranking.stagiaire.prenom,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isCurrentUser
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                        ),
                        if (isCurrentUser)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Nombre de quiz (masqué sur petit écran)
              if (!isSmallScreen)
                Expanded(
                  child: Center(
                    child: Text(
                      '${ranking.quizCount}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

              // Points avec badge moderne
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
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
                    child: Text(
                      '${ranking.totalPoints} pts',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
        return Theme.of(context).colorScheme.surfaceVariant;
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
