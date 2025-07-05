import 'package:equatable/equatable.dart';
import 'user_model.dart';

class Contact extends Equatable {
  final int id;
  final String prenom;
  final String role;
  final int userId;
  final String telephone;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;
  final UserModel user;

  const Contact({
    required this.id,
    required this.prenom,
    required this.role,
    required this.userId,
    required this.telephone,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
  });

    factory Contact.fromJson(Map<String, dynamic> json) {
      return Contact(
        id: json['id'] ?? 0,
        prenom: json['prenom'] ?? '',
        role: json['role'] ?? '',
        userId: json['user_id'] ?? 0,
        telephone: json['telephone'] ?? '',
        deletedAt: json['deleted_at'],
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
        user: UserModel.fromJson(json['user'] ?? {}), // ← Vérifiez cette ligne
      );
  }


  @override
  List<Object?> get props => [
    id,
    prenom,
    role,
    userId,
    telephone,
    deletedAt,
    createdAt,
    updatedAt,
    user,
  ];
}