// lib/features/auth/presentation/pages/all_achievements_page.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/achievement_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/all_achievements_repository.dart';
import 'package:wizi_learn/features/auth/data/repositories/achievement_repository.dart';
import 'package:wizi_learn/features/auth/presentation/widgets/achievement_badge_widget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AllAchievementsPage extends StatefulWidget {
  const AllAchievementsPage({super.key});

  @override
  State<AllAchievementsPage> createState() => _AllAchievementsPageState();
}

class _AllAchievementsPageState extends State<AllAchievementsPage> {
  late final AllAchievementsRepository _allRepo;
  late final AchievementRepository _userRepo;
  List<Achievement> _all = [];
  List<Achievement> _user = [];
  bool _isLoading = true;
  String? _selectedType; // null => Tous
  List<String> _availableTypes = [];

  @override
  void initState() {
    super.initState();
    final dio = Dio();
    final storage = FlutterSecureStorage();
    final apiClient = ApiClient(dio: dio, storage: storage);
    _allRepo = AllAchievementsRepository(apiClient: apiClient);
    _userRepo = AchievementRepository(apiClient: apiClient);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final all = await _allRepo.getAllAchievements();
    final user = await _userRepo.getUserAchievements();
    setState(() {
      _all = all;
      _user = user;
      _availableTypes = _extractTypes(all);
      _isLoading = false;
    });
  }

  List<String> _extractTypes(List<Achievement> items) {
    final set = <String>{};
    for (final a in items) {
      if (a.type.trim().isNotEmpty) set.add(a.type);
    }
    final list = set.toList()..sort();
    return list;
  }

  String _labelForType(String type) {
    switch (type) {
      case 'quiz':
        return 'Quiz';
      case 'quiz_level':
        return 'Quiz (niveau)';
      case 'quiz_all':
        return 'Tous les quiz';
      case 'quiz_all_level':
        return 'Tous (niveau)';
      case 'points':
        return 'Points';
      case 'video':
        return 'Vidéos';
      case 'parrainage':
        return 'Parrainage';
      case 'connexion_serie':
        return 'Connexions';
      case 'action':
        return 'Actions';
      default:
        return type;
    }
  }

  int _computeCrossAxisCount(double width) {
    if (width < 480) return 2;
    if (width < 800) return 3;
    if (width < 1200) return 4;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlockedIds = _user.map((a) => a.id).toSet();

    List<Achievement> filtered() {
      final source =
          _selectedType == null
              ? _all
              : _all.where((a) => a.type == _selectedType).toList();
      // Unlocked first, then by name
      source.sort((a, b) {
        final aUnlocked = unlockedIds.contains(a.id);
        final bUnlocked = unlockedIds.contains(b.id);
        if (aUnlocked != bUnlocked) return aUnlocked ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return source;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tous les badges'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: const SizedBox.shrink(),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
              : LayoutBuilder(
                builder: (context, constraints) {
                  final cols = _computeCrossAxisCount(constraints.maxWidth);
                  final items = filtered();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.emoji_events,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Badges: ${items.length}${_selectedType != null ? ' (${_labelForType(_selectedType!)})' : ''}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_user.where((u) => _selectedType == null || u.type == _selectedType).length} débloqués',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Filtres
                      if (_availableTypes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('Tous'),
                                  selected: _selectedType == null,
                                  onSelected: (v) {
                                    if (!v) return;
                                    setState(() => _selectedType = null);
                                  },
                                ),
                                const SizedBox(width: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      _availableTypes.map((t) {
                                        return ChoiceChip(
                                          label: Text(_labelForType(t)),
                                          selected: _selectedType == t,
                                          onSelected: (v) {
                                            if (!v) return;
                                            setState(() => _selectedType = t);
                                          },
                                        );
                                      }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.8,
                              ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final badge = items[index];
                            final unlocked = _user.any(
                              (a) => a.id == badge.id && a.unlockedAt != null,
                            );
                            return AchievementBadgeWidget(
                              achievement: badge,
                              unlocked: unlocked,
                              colored: false,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }
}
