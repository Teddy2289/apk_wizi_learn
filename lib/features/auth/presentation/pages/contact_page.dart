import 'package:flutter/material.dart';
import 'package:wizi_learn/features/auth/data/models/contact_model.dart';
import 'package:wizi_learn/features/auth/presentation/components/contact_card.dart';

class ContactPage extends StatelessWidget {
  final List<Contact> contacts;
  const ContactPage({super.key, required this.contacts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFEB823),
        title: const Text('Tous mes contacts'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Retrouvez ici les contacts utiles mis à votre disposition dans le cadre de votre formation.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.brown.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child:
                contacts.isEmpty
                    ? const Center(child: Text('Aucun contact disponible'))
                    : ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder:
                          (context, index) =>
                              ContactCard(contact: contacts[index]),
                    ),
          ),
        ],
      ),
    );
  }
}
