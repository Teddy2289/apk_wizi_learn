import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:wizi_learn/features/auth/data/models/mission_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/mission_repository.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/mission_card.dart';

class MissionsPage extends StatefulWidget {
  const MissionsPage({super.key});

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  late final MissionRepository _repo;
  List<Mission> _missions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repo = MissionRepository(dio: Dio());
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    setState(() => _isLoading = true);
    final missions = await _repo.getMissions();
    setState(() {
      _missions = missions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _missions.length,
              itemBuilder: (context, index) {
                final mission = _missions[index];
                return MissionCard(mission: mission);
              },
            ),
    );
  }
} 