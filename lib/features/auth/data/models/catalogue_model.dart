class Catalogue {
  final int id;
  final String titre;
  final String description;
  final String prerequis;
  final String? imageUrl;
  final String? cursusPdf;
  final String tarif;
  final String certification;
  final int statut;
  final String duree;
  final int formationId;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;

  Catalogue({
    required this.id,
    required this.titre,
    required this.description,
    required this.prerequis,
    this.imageUrl,
    this.cursusPdf,
    required this.tarif,
    required this.certification,
    required this.statut,
    required this.duree,
    required this.formationId,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Catalogue.fromJson(Map<String, dynamic> json) {
    return Catalogue(
      id: json['id'],
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      prerequis: json['prerequis'] ?? '',
      imageUrl: json['image_url'],
      cursusPdf: json['cursus_pdf'],
      tarif: json['tarif'].toString(),
      certification: json['certification'] ?? '',
      statut: json['statut'] is int ? json['statut'] : int.tryParse(json['statut'].toString()) ?? 0,
      duree: json['duree'].toString(),
      formationId: json['formation_id'],
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}