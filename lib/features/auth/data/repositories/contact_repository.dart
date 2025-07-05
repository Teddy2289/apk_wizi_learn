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
    } else {
      print('⚠ pole_relation n’est pas une liste : $poleRelation');
    }

    return contacts;
  }
}
