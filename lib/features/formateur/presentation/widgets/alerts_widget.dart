import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/data/models/alert_model.dart';

/// Widget displaying intelligent alerts for formateur dashboard
class AlertsWidget extends StatefulWidget {
  const AlertsWidget({super.key});

  @override
  State<AlertsWidget> createState() => _AlertsWidgetState();
}

class _AlertsWidgetState extends State<AlertsWidget> {
  late final ApiClient _apiClient;
  List<FormateurAlert> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(
      dio: Dio(),
      storage: const FlutterSecureStorage(),
    );
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _loading = true);
    try {
      final response = await _apiClient.get('/formateur/alerts');
      final alertsList = (response.data['alerts'] as List?)
              ?.map((a) => FormateurAlert.fromJson(a))
              .toList() ??
          [];

      setState(() {
        _alerts = alertsList;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement alertes: $e');
      setState(() => _loading = false);
    }
  }

  Color _getAlertColor(FormateurAlert alert) {
    switch (alert.type) {
      case 'danger':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getAlertIcon(FormateurAlert alert) {
    switch (alert.category) {
      case 'inactivity':
        return Icons.person_off;
      case 'deadline':
        return Icons.event_busy;
      case 'performance':
        return Icons.trending_down;
      case 'dropout':
        return Icons.exit_to_app;
      case 'never_connected':
        return Icons.person_add_disabled;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_alerts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Aucune alerte pour le moment',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.notifications_active,
                    color: Color(0xFFF7931E)),
                const SizedBox(width: 8),
                const Text(
                  'Alertes intelligentes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_alerts.length}',
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _alerts.length > 5 ? 5 : _alerts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final alert = _alerts[index];
              final color = _getAlertColor(alert);
              final icon = _getAlertIcon(alert);

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                title: Text(
                  alert.title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  alert.message,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: alert.isHighPriority
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    : null,
                onTap: alert.stagiaireId != null
                    ? () {
                        // Navigate to stagiaire profile
                        Navigator.pushNamed(
                          context,
                          '/formateur/stagiaire/${alert.stagiaireId}',
                        );
                      }
                    : null,
              );
            },
          ),
          if (_alerts.length > 5)
            TextButton(
              onPressed: () {
                // Show all alerts dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Toutes les alertes'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _alerts.length,
                        itemBuilder: (context, index) {
                          final alert = _alerts[index];
                          return ListTile(
                            leading: Icon(_getAlertIcon(alert),
                                color: _getAlertColor(alert)),
                            title: Text(alert.title),
                            subtitle: Text(alert.message),
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                );
              },
              child: Text('Voir toutes les ${_alerts.length} alertes'),
            ),
        ],
      ),
    );
  }
}
