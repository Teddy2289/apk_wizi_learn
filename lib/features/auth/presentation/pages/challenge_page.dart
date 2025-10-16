import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/repositories/challenge_repository.dart';

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
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final e = sorted[index];
            return ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(e.name),
              subtitle: Text(
                'Quizzes: ${e.quizzesCompleted} • Temps: ${_formatDuration(e.duration)}',
              ),
              trailing:
                  e.userId == '0'
                      ? null
                      : const Icon(Icons.emoji_events, color: Colors.amber),
            );
          },
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
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final e = sorted[index];
            return ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(e.name),
              subtitle: Text(
                'Points: ${e.points} • Quizzes: ${e.quizzesCompleted}',
              ),
              trailing:
                  e.userId == '0'
                      ? null
                      : const Icon(Icons.leaderboard, color: Colors.blue),
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}h ' : ''}$mm:$ss';
  }
}
