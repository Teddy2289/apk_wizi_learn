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
    print('Données reçues : ${response.data}');

    final data = response.data;
    List<Contact> contacts = [];

    // Vérifie bien que c'est une liste
    final commerciaux = data['commerciaux'];
    final formateurs = data['formateurs'];
    final poleRelation = data['pole_relation'];

    if (commerciaux is List) {
      contacts.addAll(commerciaux.map((e) => Contact.fromJson(e)).toList());
    } else {
      print('⚠ commerciaux n’est pas une liste : $commerciaux');
    }

    if (formateurs is List) {
      contacts.addAll(formateurs.map((e) => Contact.fromJson(e)).toList());
    } else {
      print('⚠ formateurs n’est pas une liste : $formateurs');
    }

    if (poleRelation is List) {
      contacts.addAll(poleRelation.map((e) => Contact.fromJson(e)).toList());
      debugPrint('Contacts du pôle relation : ${poleRelation}');
    } else {
      print('⚠ pole_relation n’est pas une liste : $poleRelation');
    }

    // Filtrer les doublons par email
    final contactsUniques = <String, Contact>{};
    for (var c in contacts) {
      contactsUniques[c.email] = c;
    }
    return contactsUniques.values.toList();
  }

  Future<List<MultipartFile>> _prepareAttachments(List<PlatformFile> files) async {
    return files.map((platformFile) {
      return MultipartFile.fromBytes(
        platformFile.bytes!,
        filename: platformFile.name,
      );
    }).toList();
  }

  Future<void> sendContactForm({
    required String email,
    required String subject,
    required String problemType,
    required String message,
    List<PlatformFile>? attachments,
  }) async {
    try {
      // Créer FormData pour le multipart
      final formData = FormData();

      // Ajouter les champs simples
      formData.fields.addAll([
        MapEntry('email', email),
        MapEntry('subject', subject),
        MapEntry('problem_type', problemType),
        MapEntry('message', message),
      ]);

      // Ajouter les pièces jointes si elles existent
      if (attachments != null && attachments.isNotEmpty) {
        for (var file in attachments) {
          if (file.bytes != null) {
            formData.files.add(
              MapEntry(
                'attachments', // Même nom pour tous les fichiers
                MultipartFile.fromBytes(
                  file.bytes!,
                  filename: file.name,
                ),
              ),
            );
          } else if (file.path != null) {
            formData.files.add(
              MapEntry(
                'attachments', // Même nom pour tous les fichiers
                await MultipartFile.fromFile(
                  file.path!,
                  filename: file.name,
                ),
              ),
            );
          }
        }
      }

      // Envoyer la requête via ApiClient
      await apiClient.post(
        '/contact',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
    } catch (e) {
      debugPrint('Error sending contact form: $e');
      throw Exception('Erreur lors de l\'envoi du formulaire: $e');
    }
  }
}