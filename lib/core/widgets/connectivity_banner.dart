import 'package:flutter/material.dart';
import 'package:wizi_learn/core/services/connectivity_service.dart';

/// Widget bannière affichant l'état de la connexion
/// Affiche "Mode hors ligne" quand pas de connexion internet
class ConnectivityBanner extends StatelessWidget {
  final ConnectivityService connectivityService;
  final Widget child;

  const ConnectivityBanner({
    super.key,
    required this.connectivityService,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: connectivityService.onConnectivityChanged,
      initialData: true,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        return Column(
          children: [
            if (!isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mode hors ligne - Données en cache',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

/// Widget icône indiquant si le contenu est disponible hors ligne
class OfflineIndicator extends StatelessWidget {
  final bool isOfflineAvailable;
  final double size;

  const OfflineIndicator({
    super.key,
    required this.isOfflineAvailable,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOfflineAvailable) return const SizedBox.shrink();

    return Tooltip(
      message: 'Disponible hors ligne',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.green.shade700,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.offline_pin,
          color: Colors.white,
          size: size,
        ),
      ),
    );
  }
}
