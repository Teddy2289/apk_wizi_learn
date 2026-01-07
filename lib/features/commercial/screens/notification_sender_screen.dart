import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/commercial_colors.dart';
import '../services/commercial_service.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';

class NotificationSenderScreen extends StatefulWidget {
  const NotificationSenderScreen({super.key});

  @override
  State<NotificationSenderScreen> createState() => _NotificationSenderScreenState();
}

class _NotificationSenderScreenState extends State<NotificationSenderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();

  String _selectedSegment = 'all';
  bool _isSending = false;

  late CommercialService _commercialService;

  final Map<String, Map<String, String>> _segmentLabels = {
    'all': {'label': 'Tous les utilisateurs', 'count': '∞'},
    'commercial': {'label': 'Commerciaux', 'count': '12'},
    'formateur': {'label': 'Formateurs', 'count': '8'},
    'stagiaire': {'label': 'Stagiaires', 'count': '156'},
  };

  @override
  void initState() {
    super.initState();
    final dio = Dio();
    _commercialService = CommercialService(dio, baseUrl: AppConstants.baseUrl);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    try {
      await _commercialService.sendNotification(
        segment: _selectedSegment,
        message: _messageController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Notification envoyée avec succès!'),
            backgroundColor: CommercialColors.success,
          ),
        );
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Erreur: $e'),
            backgroundColor: CommercialColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageLength = _messageController.text.length;

    return Scaffold(
      backgroundColor: CommercialColors.backgroundLight,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Segment selection
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: CommercialColors.borderYellow),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.users, size: 18, color: CommercialColors.primaryAmber),
                        SizedBox(width: 8),
                        Text(
                          'Segment cible',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSegment,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: CommercialColors.borderYellow),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _segmentLabels.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.value['label']!),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: CommercialColors.accentYellow.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  entry.value['count']!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: CommercialColors.primaryAmber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedSegment = value!);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_segmentLabels[_selectedSegment]!['label']} - ${_segmentLabels[_selectedSegment]!['count']} utilisateur(s)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CommercialColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Message field
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Message de la notification',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: CommercialColors.borderYellow),
                ),
                alignLabelWithHint: true,
                helperText: '$messageLength caractères',
              ),
              maxLines: 5,
              maxLength: 200,
              validator: (value) => value?.isEmpty ?? true ? 'Message requis' : null,
              onChanged: (_) => setState(() {}),
            ),
            if (messageLength > 100)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, size: 14, color: CommercialColors.warning),
                    SizedBox(width: 4),
                    Text(
                      '⚠ Les longs messages peuvent être tronqués sur mobile',
                      style: TextStyle(
                        fontSize: 12,
                        color: CommercialColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // Preview
            if (_messageController.text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CommercialColors.accentYellow.withOpacity(0.1),
                      CommercialColors.primaryAmber.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CommercialColors.borderYellow),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aperçu de la notification',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CommercialColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            LucideIcons.bell,
                            color: CommercialColors.primaryAmber,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _messageController.text,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'À l\'instant',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: CommercialColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Send button
            Container(
              decoration: BoxDecoration(
                gradient: CommercialColors.yellowGradient,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: CommercialColors.primaryAmber.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.send, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Envoyer la notification',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
