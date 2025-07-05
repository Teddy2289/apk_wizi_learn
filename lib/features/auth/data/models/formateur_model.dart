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
      id: json['id'],
      prenom: json['prenom'],
      nom: json['nom'],
      email: json['email'],
      telephone: json['telephone'],
    );
  }
}
