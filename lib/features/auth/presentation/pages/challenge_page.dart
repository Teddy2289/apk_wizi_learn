import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/repositories/challenge_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/auth_repository.dart';
import 'package:wizi_learn/features/auth/data/datasources/auth_remote_data_source.dart';

class ChallengePage extends StatefulWidget {
  const ChallengePage({super.key});

  @override
  State<ChallengePage> createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage>
    with SingleTickerProviderStateMixin {
  late final ChallengeRepository _repository;
  late TabController _tabController;
  Future<ChallengeConfig?>? _configFuture;
  Future<List<ChallengeEntry>>? _leaderboardFuture;
  int? _myStagiaireId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _repository = ChallengeRepository(apiClient: apiClient);
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _configFuture = _repository.fetchConfig();
    final config = await _configFuture;
    _leaderboardFuture = _repository.fetchLeaderboard(
      formationId: config?.formationId,
    );

    // Fetch current user stagiaire id to highlight "You"
    try {
      final apiClient = ApiClient(
        dio: Dio(),
        storage: const FlutterSecureStorage(),
      );
      final authRepo = AuthRepository(
        remoteDataSource: AuthRemoteDataSourceImpl(
          apiClient: apiClient,
          storage: const FlutterSecureStorage(),
        ),
        storage: const FlutterSecureStorage(),
      );
      final me = await authRepo.getMe();
      _myStagiaireId = me.stagiaire?.id;
    } catch (e) {
      debugPrint('Unable to fetch current user: $e');
    }
    await Future.wait([_configFuture!, _leaderboardFuture!]);
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Challenge'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Rapidité'), Tab(text: 'Points')],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [_buildFastestTab(), _buildMostPointsTab()],
              ),
    );
  }

  Widget _buildFastestTab() {
    return FutureBuilder<List<ChallengeEntry>>(
      future: _leaderboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final list = snapshot.data ?? [];
        if (list.isEmpty)
          return const Center(child: Text('Aucun participant pour le moment'));
        // Sort by duration ascending
        final sorted = [...list]
          ..sort((a, b) => a.duration.compareTo(b.duration));
        final top3 = sorted.take(3).toList();

        return Column(
          children: [
            _buildPodium(top3, isTime: true),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final e = sorted[index];
                  final isMe =
                      _myStagiaireId != null &&
                      _myStagiaireId.toString() == e.userId;
                  return Container(
                    color: isMe ? Colors.blue.withOpacity(0.08) : null,
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(e.name + (isMe ? ' (Vous)' : '')),
                      subtitle: Text(
                        'Quizzes: ${e.quizzesCompleted}  Temps: ${_formatDuration(e.duration)}',
                      ),
                      trailing:
                          e.userId == '0'
                              ? null
                              : const Icon(
                                Icons.emoji_events,
                                color: Colors.amber,
                              ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMostPointsTab() {
    return FutureBuilder<List<ChallengeEntry>>(
      future: _leaderboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final list = snapshot.data ?? [];
        if (list.isEmpty)
          return const Center(child: Text('Aucun participant pour le moment'));
        // Sort by points descending
        final sorted = [...list]..sort((a, b) => b.points.compareTo(a.points));
        final top3 = sorted.take(3).toList();
        return Column(
          children: [
            _buildPodium(top3, isTime: false),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final e = sorted[index];
                  final isMe =
                      _myStagiaireId != null &&
                      _myStagiaireId.toString() == e.userId;
                  return Container(
                    color: isMe ? Colors.blue.withOpacity(0.08) : null,
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(e.name + (isMe ? ' (Vous)' : '')),
                      subtitle: Text(
                        'Points: ${e.points}  Quizzes: ${e.quizzesCompleted}',
                      ),
                      trailing:
                          e.userId == '0'
                              ? null
                              : const Icon(
                                Icons.leaderboard,
                                color: Colors.blue,
                              ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPodium(List<ChallengeEntry> top, {required bool isTime}) {
    // Basic podium visuals: 2-1-3 columns
    final a = top.length > 0 ? top[0] : null;
    final b = top.length > 1 ? top[1] : null;
    final c = top.length > 2 ? top[2] : null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _podiumCard(b, 2, isTime),
          _podiumCard(a, 1, isTime),
          _podiumCard(c, 3, isTime),
        ],
      ),
    );
  }

  Widget _podiumCard(ChallengeEntry? e, int rank, bool isTime) {
    if (e == null) return SizedBox(width: 80, height: 80);
    final value = isTime ? _formatDuration(e.duration) : '${e.points} pts';
    final color =
        rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey : Colors.brown);
    return Column(
      children: [
        Container(
          width: 80,
          height: rank == 1 ? 96 : 72,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 2),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                e.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text('#$rank', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}h ' : ''}$mm:$ss';
  }
}
