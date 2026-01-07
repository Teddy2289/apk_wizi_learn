import 'package:flutter/material.dart';

class InscriptionRequestsPage extends StatefulWidget {
  const InscriptionRequestsPage({super.key});

  @override
  State<InscriptionRequestsPage> createState() =>
      _InscriptionRequestsPageState();
}

class _InscriptionRequestsPageState extends State<InscriptionRequestsPage> {
  final bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // _repository = InscriptionRequestRepository(Dio());
    // _loadRequests();
  }

  Future<void> _loadRequests() async {
    // setState(() => _isLoading = true);
    // final requests = await _repository.list();
    // setState(() {
    //   _requests = requests;
    //   _isLoading = false;
    // });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes demandes d\'inscription'),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
              : Center(child: Text('Feature not implemented.')),
    );
  }
}
