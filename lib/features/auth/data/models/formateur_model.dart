class FormateurModel {
  final int id;
  final String prenom;
  final String nom;
  final String email;
  final String telephone;

  FormateurModel({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.email,
    required this.telephone,
  });

  factory FormateurModel.fromJson(Map<String, dynamic> json) {
    return FormateurModel(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      prenom: json['prenom']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      telephone: json['telephone']?.toString() ?? '',
    );
  }
}
