import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:wizi_learn/core/constants/app_constants.dart';
import 'package:wizi_learn/core/network/api_client.dart';
import 'package:wizi_learn/features/auth/data/models/contact_model.dart';

class ContactRepository {
  final ApiClient apiClient;

  ContactRepository({required this.apiClient});

  Future<List<Contact>> getContacts() async {
    final response = await apiClient.get(AppConstants.contact);
    debugPrint('Données reçues : ${response.data}');

    final data = response.data;
    List<Contact> contacts = [];

    final commerciaux = data['commerciaux'];
    final formateurs = data['formateurs'];
    final poleRelation = data['pole_relation'];
    final poleSav = data['pole_sav'];

    // CORRECTION : Les données sont déjà plates, pas besoin de _parseContactWithUser
    if (commerciaux is List) {
      contacts.addAll(commerciaux.map((e) => Contact.fromJson(e)).toList());
    } else {
      debugPrint('⚠ commerciaux n\'est pas une liste : $commerciaux');
    }

    if (formateurs is List) {
      contacts.addAll(formateurs.map((e) => Contact.fromJson(e)).toList());
    } else {
      debugPrint('⚠ formateurs n\'est pas une liste : $formateurs');
    }

    if (poleRelation is List) {
      contacts.addAll(poleRelation.map((e) => Contact.fromJson(e)).toList());
      // debugPrint('Contacts du pôle relation : $poleRelation');
    } else {
      debugPrint('⚠ pole_relation n\'est pas une liste : $poleRelation');
    }

    if (poleSav is List) {
      contacts.addAll(poleSav.map((e) => Contact.fromJson(e)).toList());
    } else {
      debugPrint('⚠ pole_sav n\'est pas une liste : $poleSav');
    }

    // Filtrer les doublons par email
    final contactsUniques = <String, Contact>{};
    for (var c in contacts) {
      if (c.email.isNotEmpty) {
        contactsUniques[c.email] = c;
      }
    }
    return contactsUniques.values.toList();
  }

  // SUPPRIMER cette méthode car elle n'est plus nécessaire
  // Contact _parseContactWithUser(Map<String, dynamic> data, String type) { ... }

  Future<void> sendContactForm({
    required String email,
    required String subject,
    required String problemType,
    required String message,
    List<PlatformFile>? attachments,
  }) async {
    try {
      final formData = FormData();

      formData.fields.addAll([
        MapEntry('email', email),
        MapEntry('subject', subject),
        MapEntry('problem_type', problemType),
        MapEntry('message', message),
      ]);

      if (attachments != null && attachments.isNotEmpty) {
        for (var file in attachments) {
          if (file.bytes != null) {
            formData.files.add(
              MapEntry(
                'attachments',
                MultipartFile.fromBytes(file.bytes!, filename: file.name),
              ),
            );
          } else if (file.path != null) {
            formData.files.add(
              MapEntry(
                'attachments',
                await MultipartFile.fromFile(file.path!, filename: file.name),
              ),
            );
          }
        }
      }

      await apiClient.post(
        '/contact',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } catch (e) {
      debugPrint('Error sending contact form: $e');
      throw Exception('Erreur lors de l\'envoi du formulaire: $e');
    }
  }
}
