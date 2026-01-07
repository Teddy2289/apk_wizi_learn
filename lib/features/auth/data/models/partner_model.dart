import 'package:equatable/equatable.dart';
import 'package:wizi_learn/features/auth/data/models/contact_model.dart';

class PartnerContact extends Equatable {
  final String? prenom;
  final String? nom;
  final String? fonction;
  final String? email;
  final String? tel;

  const PartnerContact({
    this.prenom,
    this.nom,
    this.fonction,
    this.email,
    this.tel,
  });

  factory PartnerContact.fromJson(Map<String, dynamic> json) {
    return PartnerContact(
      prenom: json['prenom']?.toString(),
      nom: json['nom']?.toString(),
      fonction: json['fonction']?.toString(),
      email: json['email']?.toString(),
      tel: json['tel']?.toString(),
    );
  }

  @override
  List<Object?> get props => [prenom, nom, fonction, email, tel];

  Contact toContact() {
    final displayName = [
      prenom,
      nom,
    ].where((e) => (e ?? '').trim().isNotEmpty).join(' ');
    return Contact(
      id: 0,
      name: displayName.isEmpty ? 'Contact partenaire' : displayName,
      type: (fonction ?? 'Contact partenaire'),
      telephone: tel ?? '',
      email: email ?? '',
      prenom: prenom ?? '',
      civilite: '',
    );
  }
}

class Partner extends Equatable {
  final String identifiant;
  final String type;
  final String adresse;
  final String ville;
  final String departement;
  final String codePostal;
  final String? logo; // relative or absolute URL
  final bool? actif;
  final List<PartnerContact> contacts;

  const Partner({
    required this.identifiant,
    required this.type,
    required this.adresse,
    required this.ville,
    required this.departement,
    required this.codePostal,
    this.logo,
    this.actif,
    this.contacts = const [],
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    final rawContacts = json['contacts'];
    final parsedContacts =
        (rawContacts is List)
            ? rawContacts
                .whereType<Map<String, dynamic>>()
                .map<PartnerContact>(
                  (e) => PartnerContact.fromJson(e),
                )
                .toList()
            : <PartnerContact>[];

    return Partner(
      identifiant: json['identifiant']?.toString() ?? '-',
      type: json['type']?.toString() ?? '-',
      adresse: json['adresse']?.toString() ?? '-',
      ville: json['ville']?.toString() ?? '-',
      departement: json['departement']?.toString() ?? '-',
      codePostal: json['code_postal']?.toString() ?? '-',
      logo: json['logo']?.toString(),
      actif: json['actif'] is bool ? json['actif'] as bool : null,
      contacts: parsedContacts,
    );
  }

  @override
  List<Object?> get props => [
    identifiant,
    type,
    adresse,
    ville,
    departement,
    codePostal,
    logo,
    actif,
    contacts,
  ];

  List<Contact> toContactList() {
    return contacts.map((pc) => pc.toContact()).toList();
  }
}
