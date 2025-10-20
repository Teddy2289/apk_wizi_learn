import 'package:equatable/equatable.dart';

class Contact extends Equatable {
  final int id;
  final String name;
  final String type;
  final String telephone;
  final String email;
  final String? image;
  final String? civilite;
  final String? role;
  final List<dynamic>? formations;

  const Contact({
    required this.id,
    required this.name,
    required this.type,
    required this.telephone,
    required this.email,
    this.image,
    this.civilite,
    this.role,
    this.formations,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? 0, // Valeur par défaut si null
      name: json['name'] ?? 'Inconnu', // Valeur par défaut
      type: json['type'] ?? 'Autre', // Valeur par défaut
      telephone: json['telephone'] ?? '',
      email: json['email'] ?? '',
      formations: json['formations'],
      image: json['image'] ?? json['avatar'] ?? null,
      civilite: json['civilite'],
      role: json['role'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    telephone,
    email,
    image,
    civilite,
    role,
    formations,
  ];
}

class ContactFormModel {
  final String email;
  final String subject;
  final String problemType;
  final String message;
  final List<String>? attachmentPaths;

  ContactFormModel({
    required this.email,
    required this.subject,
    required this.problemType,
    required this.message,
    this.attachmentPaths,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'subject': subject,
      'problem_type': problemType,
      'message': message,
    };
  }
}
