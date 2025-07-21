import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:wizi_learn/features/auth/data/models/inscription_request_model.dart';
import 'package:wizi_learn/features/auth/data/repositories/inscription_request_repository.dart';

class InscriptionRequestsPage extends StatefulWidget {
  const InscriptionRequestsPage({Key? key}) : super(key: key);

  @override
  State<InscriptionRequestsPage> createState() => _InscriptionRequestsPageState();
}

class _InscriptionRequestsPageState extends State<InscriptionRequestsPage> {
  late final InscriptionRequestRepository _repository;
  List<InscriptionRequest> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = InscriptionRequestRepository(Dio());
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    final requests = await _repository.list();
    setState(() {
      _requests = requests;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes demandes d\'inscription'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _requests.isEmpty
              ? Center(child: Text('Aucune demande d\'inscription.'))
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text('Catalogue #${req.catalogueFormationId}'), // Remplacer par le vrai nom si dispo
                        subtitle: Text('Statut : ${req.status}'),
                        trailing: Text(req.createdAt != null ? req.createdAt!.substring(0, 10) : ''),
                      ),
                    );
                  },
                ),
    );
  }
} 