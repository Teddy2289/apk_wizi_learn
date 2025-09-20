import 'package:flutter/material.dart';

class AvatarSelectorDialog extends StatelessWidget {
  final List<String> avatarPaths;
  final String? selectedAvatar;
  const AvatarSelectorDialog({super.key, required this.avatarPaths, this.selectedAvatar});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choisis ton avatar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              itemCount: avatarPaths.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final path = avatarPaths[index];
                final isSelected = path == selectedAvatar;
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(path),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(path, width: 64, height: 64),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 