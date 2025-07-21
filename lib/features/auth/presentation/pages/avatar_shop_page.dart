import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:wizi_learn/features/auth/data/models/avatar_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/avatar_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarShopPage extends StatefulWidget {
  const AvatarShopPage({Key? key}) : super(key: key);

  @override
  State<AvatarShopPage> createState() => _AvatarShopPageState();
}

class _AvatarShopPageState extends State<AvatarShopPage> {
  late final AvatarRepository _repo;
  List<Avatar> _all = [];
  List<Avatar> _unlocked = [];
  bool _isLoading = true;
  String? _selectedAvatar;

  @override
  void initState() {
    super.initState();
    _repo = AvatarRepository(dio: Dio());
    _loadAvatars();
    _loadSelectedAvatar();
  }

  Future<void> _loadAvatars() async {
    setState(() => _isLoading = true);
    final all = await _repo.getAllAvatars();
    final unlocked = await _repo.getUnlockedAvatars();
    setState(() {
      _all = all;
      _unlocked = unlocked;
      _isLoading = false;
    });
  }

  Future<void> _loadSelectedAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAvatar = prefs.getString('selected_avatar');
    });
  }

  Future<void> _selectAvatar(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_avatar', path);
    setState(() {
      _selectedAvatar = path;
    });
  }

  Future<void> _unlockAvatar(Avatar avatar) async {
    await _repo.unlockAvatar(avatar.id);
    await _loadAvatars();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boutique d\'avatars'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : GridView.builder(
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
                  onTap: isUnlocked
                      ? () => _selectAvatar(avatar.image)
                      : null,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
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
                                color: isUnlocked ? theme.colorScheme.onSurface : Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (!isUnlocked)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  children: [
                                    if (avatar.pricePoints > 0)
                                      Text('${avatar.pricePoints} pts', style: theme.textTheme.bodySmall),
                                    if (avatar.unlockCondition != null)
                                      Text(avatar.unlockCondition!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey), textAlign: TextAlign.center),
                                    ElevatedButton(
                                      onPressed: () => _unlockAvatar(avatar),
                                      child: const Text('Débloquer'),
                                    ),
                                  ],
                                ),
                              ),
                            if (isUnlocked && isSelected)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Icon(Icons.check_circle, color: theme.colorScheme.primary),
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