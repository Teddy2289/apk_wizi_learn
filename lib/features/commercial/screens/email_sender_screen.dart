import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/commercial_colors.dart';
import '../models/user.dart';
import '../widgets/user_avatar.dart';
import '../services/commercial_service.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';

class EmailSenderScreen extends StatefulWidget {
  const EmailSenderScreen({super.key});

  @override
  State<EmailSenderScreen> createState() => _EmailSenderScreenState();
}

class _EmailSenderScreenState extends State<EmailSenderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();

  List<User> _users = [];
  List<User> _filteredUsers = [];
  Set<String> _selectedUserIds = {};
  bool _isLoading = false;
  bool _isSending = false;
  bool _showUserList = false;

  late CommercialService _commercialService;

  @override
  void initState() {
    super.initState();
    final dio = Dio();
    _commercialService = CommercialService(dio, baseUrl: AppConstants.baseUrl);
    _loadUsers();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _commercialService.getUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _users.where((user) {
        return user.name.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _toggleUser(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedUserIds = _filteredUsers.map((u) => u.id).toSet();
    });
  }

  void _clearAll() {
    setState(() {
      _selectedUserIds.clear();
    });
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate() || _selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins un destinataire')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await _commercialService.sendEmail(
        userIds: _selectedUserIds.toList(),
        subject: _subjectController.text,
        message: _messageController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Email envoyé avec succès!'),
            backgroundColor: CommercialColors.success,
          ),
        );
        _subjectController.clear();
        _messageController.clear();
        _selectedUserIds.clear();
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
    return Scaffold(
      backgroundColor: CommercialColors.backgroundLight,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User selection card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: CommercialColors.borderOrange),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.users, size: 18, color: CommercialColors.primaryOrange),
                            const SizedBox(width: 8),
                            Text(
                              'Destinataires (${_selectedUserIds.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => setState(() => _showUserList = !_showUserList),
                          child: Text(_showUserList ? 'Masquer' : 'Sélectionner'),
                        ),
                      ],
                    ),
                    if (_showUserList) ...[
                      const SizedBox(height: 12),
                      // Search bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Rechercher...',
                          prefixIcon: const Icon(LucideIcons.search, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: CommercialColors.borderOrange),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: _filterUsers,
                      ),
                      const SizedBox(height: 8),
                      // Select/Clear all buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _selectAll,
                              child: const Text('Tout sélectionner'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _clearAll,
                              child: const Text('Tout désélectionner'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // User list
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = _filteredUsers[index];
                                  final isSelected = _selectedUserIds.contains(user.id);
                                  return CheckboxListTile(
                                    value: isSelected,
                                    onChanged: (_) => _toggleUser(user.id),
                                    title: Text(user.name, style: const TextStyle(fontSize: 14)),
                                    subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
                                    secondary: UserAvatar(name: user.name, size: 36),
                                    activeColor: CommercialColors.primaryOrange,
                                  );
                                },
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Subject field
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Objet',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: CommercialColors.borderOrange),
                ),
                prefixIcon: const Icon(LucideIcons.mail, size: 18),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            // Message field
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: CommercialColors.borderOrange),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
            ),
            const SizedBox(height: 20),
            // Send button
            Container(
              decoration: BoxDecoration(
                gradient: CommercialColors.orangeGradient,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: CommercialColors.primaryOrange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendEmail,
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.send, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Envoyer à ${_selectedUserIds.length} destinataire(s)',
                            style: const TextStyle(
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
