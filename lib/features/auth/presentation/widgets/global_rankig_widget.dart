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

    if (widget.rankings.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
        ),
      );
    }

    // Séparation top 3 et reste
    final podium = widget.rankings.take(3).toList();
    final rest = widget.rankings.length > 3 ? widget.rankings.sublist(3) : [];
    final myIndex = widget.rankings.indexWhere((r) => int.tryParse(r.stagiaire.id.toString()) == _connectedStagiaireId);
    final isCurrentUserInPodium = myIndex >= 0 && myIndex < 3;
    final isCurrentUserInRest = myIndex >= 3;

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
            // Podium
            _buildPodium(context, podium, isSmallScreen),
            const SizedBox(height: 16),
            // Liste classique
            if (rest.isNotEmpty)
              ...[
                _buildHeader(context, isSmallScreen),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rest.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (_, index) {
                    final ranking = rest[index];
                    final isCurrentUser = int.tryParse(ranking.stagiaire.id.toString()) == _connectedStagiaireId;
                    return _buildRankingItem(context, ranking, isSmallScreen, isCurrentUser: isCurrentUser);
                  },
                ),
              ],
            // Si l'utilisateur n'est pas dans le top, l'afficher en bas
            if (isCurrentUserInRest)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildRankingItem(context, widget.rankings[myIndex], isSmallScreen, isCurrentUser: true, highlight: true),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium(BuildContext context, List<GlobalRanking> podium, bool isSmallScreen) {
    // Ordre d'affichage : 2e, 1er, 3e
    final List<int> order = [1, 0, 2];
    final double base = 60;
    final List<double> heights = [base, base + 30, base - 10];
    final List<double> sizes = [48, 64, 40];
    final List<Color> colors = [Colors.grey, Colors.amber, Colors.orange];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final idx = order[i];
        if (idx >= podium.length) return const SizedBox(width: 60);
        final ranking = podium[idx];
        final isCurrentUser = int.tryParse(ranking.stagiaire.id.toString()) == _connectedStagiaireId;
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: heights[i],
                    width: sizes[i],
                    decoration: BoxDecoration(
                      color: colors[i].withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors[i], width: 2),
                    ),
                  ),
                  CircleAvatar(
                    radius: sizes[i] / 2,
                    backgroundImage: NetworkImage(
                      '${AppConstants.baseUrlImg}/${ranking.stagiaire.image}',
                    ),
                    backgroundColor: Colors.white,
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
              const SizedBox(height: 8),
              Text(
                ranking.stagiaire.prenom,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? Theme.of(context).primaryColor : (colors[i] is MaterialColor ? (colors[i] as MaterialColor).shade800 : colors[i]),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '${ranking.totalPoints} pts',
                style: TextStyle(
                  color: (colors[i] is MaterialColor ? (colors[i] as MaterialColor).shade800 : colors[i]),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors[i].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${idx + 1}${idx == 0 ? 'er' : 'e'}',
                  style: TextStyle(
                    color: (colors[i] is MaterialColor ? (colors[i] as MaterialColor).shade800 : colors[i]),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
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
    bool isSmallScreen, {
    bool isCurrentUser = false,
    bool highlight = false,
  }) {
    return Container(
      margin: highlight ? const EdgeInsets.symmetric(vertical: 8) : null,
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Theme.of(context).primaryColor.withOpacity(0.08)
            : Colors.transparent,
        border: isCurrentUser
            ? Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                width: 1.5,
              )
            : null,
        borderRadius: BorderRadius.circular(8),
        boxShadow: highlight
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
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
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: isSmallScreen ? 20 : 24,
                    backgroundImage: NetworkImage(
                      '${AppConstants.baseUrlImg}/${ranking.stagiaire.image}',
                    ),
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    ranking.stagiaire.prenom,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isCurrentUser
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            if (!isSmallScreen)
              Expanded(
                child: Center(
                  child: Text(
                    '${ranking.quizCount}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
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
