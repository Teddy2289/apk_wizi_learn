import 'package:equatable/equatable.dart';
import 'user_model.dart';

class Contact extends Equatable {
  final int id;
  final String prenom;
  final String role;
  final String telephone;
  final String email;
  final List<dynamic>? formations;

  const Contact({
    required this.id,
    required this.prenom,
    required this.role,
    required this.telephone,
    required this.email,
    this.formations,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      prenom: json['name'], // correspond à "name" dans l'API
      role: json['type'], // correspond à "type" dans l'API
      telephone: json['telephone'],
      email: json['email'],
      formations: json['formations'],
    );
  }

  @override
  List<Object?> get props => [id, prenom, role, telephone, email, formations];
}
