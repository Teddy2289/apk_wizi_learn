import 'package:flutter/material.dart';

/// Widget helper pour ajouter automatiquement un espacement en pied de page
/// afin d'éviter que le contenu soit masqué par la barre de navigation système
class SafeAreaBottom extends StatelessWidget {
  final Widget child;
  final double minBottomPadding;

  const SafeAreaBottom({
    super.key,
    required this.child,
    this.minBottomPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final effectivePadding =
        bottomInset > 0 ? bottomInset + 8.0 : minBottomPadding;

    return Padding(
      padding: EdgeInsets.only(bottom: effectivePadding),
      child: child,
    );
  }
}

/// Extension helper pour SingleChildScrollView et autres widgets scrollables
/// Ajoute automatiquement bottom padding à la fin du contenu
extension SafeAreaBottomExtension on Widget {
  /// Enveloppe le widget dans un SafeAreaBottom
  Widget withSafeAreaBottom({double minBottomPadding = 16.0}) {
    return SafeAreaBottom(minBottomPadding: minBottomPadding, child: this);
  }
}
