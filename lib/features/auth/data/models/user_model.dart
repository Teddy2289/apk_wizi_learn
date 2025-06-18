import 'package:equatable/equatable.dart';
import 'stagiaire_model.dart';
// Models
class UserModel extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final String role;
  final String? image;
  final String createdAt;
  final String updatedAt;
  final String? lastLoginAt;
  final String? lastActivityAt;
  final String? lastLoginIp;
  final bool isOnline;
  final StagiaireModel? stagiaire;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    required this.role,
    this.image,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.lastActivityAt,
    this.lastLoginIp,
    required this.isOnline,
    this.stagiaire,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      emailVerifiedAt: json['email_verified_at'],
      role: json['role'],
      image: json['image'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      lastLoginAt: json['last_login_at'],
      lastActivityAt: json['last_activity_at'],
      lastLoginIp: json['last_login_ip'],
      isOnline: json['is_online'],
      stagiaire: json['stagiaire'] != null
          ? StagiaireModel.fromJson(json['stagiaire'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'role': role,
      'image': image,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'last_login_at': lastLoginAt,
      'last_activity_at': lastActivityAt,
      'last_login_ip': lastLoginIp,
      'is_online': isOnline,
      'stagiaire': stagiaire?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    emailVerifiedAt,
    role,
    image,
    createdAt,
    updatedAt,
    lastLoginAt,
    lastActivityAt,
    lastLoginIp,
    isOnline,
    stagiaire,
  ];
}