import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/formateur/presentation/theme/formateur_theme.dart';

class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> with AutomaticKeepAliveClientMixin {
  final ApiClient _apiClient = ApiClient(
    dio: Dio(),
    storage: const FlutterSecureStorage(),
  );

  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  
  List<dynamic> _stagiaires = [];
  List<int> _selectedIds = [];
  bool _loading = true;
  bool _sending = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStagiaires();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadStagiaires() async {
    try {
      final response = await _apiClient.get('/formateur/stagiaires');
      if (mounted) {
        setState(() {
          _stagiaires = response.data['stagiaires'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement stagiaires: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendNotification() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins un stagiaire'), backgroundColor: FormateurTheme.error),
      );
      return;
    }

    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre et le message sont requis'), backgroundColor: FormateurTheme.error),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await _apiClient.post('/formateur/send-notification', data: {
        'recipient_ids': _selectedIds,
        'title': _titleController.text,
        'body': _messageController.text,
        'data': {},
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification envoyée à ${_selectedIds.length} stagiaire(s)'),
            backgroundColor: FormateurTheme.success,
          ),
        );
        
        _titleController.clear();
        _messageController.clear();
        setState(() => _selectedIds = []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'envoi'),
            backgroundColor: FormateurTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final filteredStagiaires = _stagiaires.where((s) {
      final fullName = '${s['prenom']} ${s['nom']} ${s['email']}'.toLowerCase();
      return fullName.contains(_searchQuery.toLowerCase());
    }).toList();

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: FormateurTheme.accent));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélection destinataires
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FormateurTheme.border),
              boxShadow: FormateurTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DESTINATAIRES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: FormateurTheme.textTertiary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: FormateurTheme.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedIds.length} sélectionné(s)',
                          style: const TextStyle(
                            color: FormateurTheme.accentDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 11
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: FormateurTheme.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un stagiaire...',
                        hintStyle: TextStyle(color: FormateurTheme.textTertiary, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: FormateurTheme.textTertiary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(color: FormateurTheme.textPrimary),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  activeColor: FormateurTheme.accentDark,
                  title: Text('Tous (${filteredStagiaires.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FormateurTheme.textPrimary)),
                  value: _selectedIds.length == filteredStagiaires.length &&
                      filteredStagiaires.isNotEmpty,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedIds = filteredStagiaires.map((s) => s['id'] as int).toList();
                      } else {
                        _selectedIds = [];
                      }
                    });
                  },
                ),
                const Divider(height: 1, color: FormateurTheme.border),
                Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: filteredStagiaires.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 20, endIndent: 20, color: FormateurTheme.border),
                    itemBuilder: (context, index) {
                      final stagiaire = filteredStagiaires[index];
                      final id = stagiaire['id'] as int;
                      final isSelected = _selectedIds.contains(id);

                      return CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                        activeColor: FormateurTheme.accentDark,
                        tileColor: isSelected ? FormateurTheme.accent.withOpacity(0.05) : null,
                        title: Text(
                          '${stagiaire['prenom']} ${stagiaire['nom']}',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: FormateurTheme.textPrimary,
                            fontSize: 14
                          )
                        ),
                        subtitle: Text(stagiaire['email'], style: const TextStyle(color: FormateurTheme.textTertiary, fontSize: 12)),
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedIds.add(id);
                            } else {
                              _selectedIds.remove(id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Titre
          const Text('CONTENU DE LA NOTIFICATION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: FormateurTheme.textTertiary, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FormateurTheme.border),
              boxShadow: FormateurTheme.cardShadow
            ),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                labelStyle: TextStyle(color: FormateurTheme.textTertiary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, color: FormateurTheme.textPrimary),
              maxLength: 100,
            ),
          ),
          const SizedBox(height: 16),

          // Message
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FormateurTheme.border),
              boxShadow: FormateurTheme.cardShadow
            ),
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                labelStyle: TextStyle(color: FormateurTheme.textTertiary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                alignLabelWithHint: true,
              ),
              style: const TextStyle(color: FormateurTheme.textPrimary),
              maxLines: 6,
              maxLength: 500,
            ),
          ),
          const SizedBox(height: 32),

          // Bouton envoi
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _sendNotification,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(
                _sending
                    ? 'ENVOI EN COURS...'
                    : 'ENVOYER LA NOTIFICATION',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: FormateurTheme.accentDark,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                disabledBackgroundColor: FormateurTheme.textTertiary.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
