import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wizi_learn/core/network/api_client.dart';

class SendNotificationPage extends StatefulWidget {
  const SendNotificationPage({super.key});

  @override
  State<SendNotificationPage> createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage> {
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

  Future<void> _loadStagiaires() async {
    try {
      final response = await _apiClient.get('/formateur/stagiaires');
      setState(() {
        _stagiaires = response.data['stagiaires'] ?? [];
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement stagiaires: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _sendNotification() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins un stagiaire')),
      );
      return;
    }

    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre et le message sont requis')),
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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStagiaires = _stagiaires.where((s) {
      final fullName = '${s['prenom']} ${s['nom']} ${s['email']}'.toLowerCase();
      return fullName.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Envoyer Notification'),
        backgroundColor: const Color(0xFFF7931E),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sélection destinataires
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Destinataires',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Chip(
                                label: Text('${_selectedIds.length} sélectionné(s)'),
                                backgroundColor: Colors.blue.shade100,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Rechercher...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) => setState(() => _searchQuery = value),
                          ),
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          title: Text('Tous (${filteredStagiaires.length})'),
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
                        const Divider(height: 1),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredStagiaires.length,
                            itemBuilder: (context, index) {
                              final stagiaire = filteredStagiaires[index];
                              final id = stagiaire['id'] as int;

                              return CheckboxListTile(
                                title: Text('${stagiaire['prenom']} ${stagiaire['nom']}'),
                                subtitle: Text(stagiaire['email']),
                                value: _selectedIds.contains(id),
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
                  const SizedBox(height: 16),

                  // Titre
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),

                  // Message
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 24),

                  // Bouton envoi
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sending ? null : _sendNotification,
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _sending
                            ? 'Envoi en cours...'
                            : 'Envoyer à ${_selectedIds.length} stagiaire(s)',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: const Color(0xFFF7931E),
                      ),
                    ),
                  ),
                ],
              ),
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
