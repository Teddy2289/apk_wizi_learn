class Media {
  final int id;
  final String titre;
  final String? description;
  final String url;
  final String type;
  final String categorie;
  final int? duree;
  final int formationId;

  Media({
    required this.id,
    required this.titre,
    this.description,
    required this.url,
    required this.type,
    required this.categorie,
    this.duree,
    required this.formationId,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] as int? ?? 0, // Valeur par défaut si null
      titre: json['titre'] as String? ?? '', // Valeur par défaut si null
      description: json['description'] as String?,
      url: json['url'] as String? ?? '', // Valeur par défaut si null
      type: json['type'] as String? ?? '', // Valeur par défaut si null
      categorie: json['categorie'] as String? ?? '', // Valeur par défaut si null
      duree: json['duree'] as int?,
      formationId: json['formation_id'] as int? ?? 0, // Valeur par défaut si null
    );
  }
}