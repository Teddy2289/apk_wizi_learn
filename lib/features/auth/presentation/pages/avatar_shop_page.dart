import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:wizi_learn/features/auth/data/models/avatar_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/avatar_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class AvatarShopPage extends StatefulWidget {
  const AvatarShopPage({super.key});

  @override
  State<AvatarShopPage> createState() => _AvatarShopPageState();
}

class _AvatarShopPageState extends State<AvatarShopPage> {
  late final AvatarRepository _repo;
  List<Avatar> _all = [];
  List<Avatar> _unlocked = [];
  bool _isLoading = true;
  String? _selectedAvatar;

  // GlobalKeys pour le tutoriel interactif
  final GlobalKey _keyGrid = GlobalKey();
  final GlobalKey _keyFirstAvatar = GlobalKey();
  final GlobalKey _keyUnlock = GlobalKey();
  void _showTutorial() {
    TutorialCoachMark(
      targets: _buildTargets(),
      colorShadow: Colors.black,
      textSkip: 'Passer',
      paddingFocus: 8,
      opacityShadow: 0.8,
      onFinish: () {},
      onSkip: () {
        return true;
      },
    ).show(context: context);
  }

  List<TargetFocus> _buildTargets() {
    return [
      TargetFocus(
        identify: 'grid',
        keyTarget: _keyGrid,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              'Voici la boutique d’avatars. Choisis ton style !',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'firstavatar',
        keyTarget: _keyFirstAvatar,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              'Clique sur un avatar débloqué pour le sélectionner.',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'unlock',
        keyTarget: _keyUnlock,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              'Débloque de nouveaux avatars avec tes points ou en remplissant des conditions spéciales.',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boutique d\'avatars'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Voir le tutoriel',
            onPressed: _showTutorial,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
              : GridView.builder(
                key: _keyGrid,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: _all.length,
                itemBuilder: (context, index) {
                  final avatar = _all[index];
                  final isUnlocked = _unlocked.any((a) => a.id == avatar.id);
                  final isSelected = _selectedAvatar == avatar.image;
                  return GestureDetector(
                    key: index == 0 ? _keyFirstAvatar : null,
                    onTap:
                        isUnlocked ? () => _selectAvatar(avatar.image) : null,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  isSelected
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: isUnlocked ? Colors.white : Colors.grey[200],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/${avatar.image}',
                                width: 64,
                                height: 64,
                                color: isUnlocked ? null : Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                avatar.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isUnlocked
                                          ? theme.colorScheme.onSurface
                                          : Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (!isUnlocked)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Column(
                                    children: [
                                      if (avatar.pricePoints > 0)
                                        Text(
                                          '${avatar.pricePoints} pts',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      if (avatar.unlockCondition != null)
                                        Text(
                                          avatar.unlockCondition!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(color: Colors.grey),
                                          textAlign: TextAlign.center,
                                        ),
                                      ElevatedButton(
                                        key: _keyUnlock,
                                        onPressed: () => _unlockAvatar(avatar),
                                        child: const Text('Débloquer'),
                                      ),
                                    ],
                                  ),
                                ),
                              if (isUnlocked && isSelected)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
