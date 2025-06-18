class Media {
  final String id;
  final String titre;
  final String type; // video, audio, document, image
  final String categorie;
  final int duree;
  final String url;
  final String category; // 'tutoriel' ou 'astuce'

  Media({
    required this.id,
    required this.titre,
    required this.type,
    required this.categorie,
    required this.duree,
    required this.url,
    required this.category,
  });

  factory Media.fromJson(Map<String, dynamic> json) => Media(
        id: json['id'].toString(),
        titre: json['titre'] ?? '',
        type: json['type'] ?? '',
        categorie: json['categorie'] ?? '',
        duree: json['duree'] is int ? json['duree'] : int.tryParse(json['duree'].toString()) ?? 0,
        url: json['url'] ?? '',
        category: json['category'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titre': titre,
        'type': type,
        'categorie': categorie,
        'duree': duree,
        'url': url,
        'category': category,
      };
}
