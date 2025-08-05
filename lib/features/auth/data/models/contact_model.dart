import 'package:equatable/equatable.dart';

class Contact extends Equatable {
  final int id;
  final String name;
  final String type;
  final String telephone;
  final String email;
  final List<dynamic>? formations;

  const Contact({
    required this.id,
    required this.name,
    required this.type,
    required this.telephone,
    required this.email,
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
    );
  }

  @override
  List<Object?> get props => [id, name, type, telephone, email, formations];
}