class Media {
  final int id;
  final String titre;
  final String? description;
  final String url;
  final String? videoUrl; // Virtual attribute from backend
  final String? subtitleUrl; // Virtual attribute from backend
  final String type;
  final String categorie;
  final int? duree;
  final int formationId;
  final String videoPlatform;
  final String? videoFilePath;
  final String? subtitleFilePath;
  final String? subtitleLanguage;

  Media({
    required this.id,
    required this.titre,
    this.description,
    required this.url,
    this.videoUrl,
    this.subtitleUrl,
    required this.type,
    required this.categorie,
    this.duree,
    required this.formationId,
    this.videoPlatform = 'server', // Default to server for server-hosted videos
    this.videoFilePath,
    this.subtitleFilePath,
    this.subtitleLanguage,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] as int? ?? 0,
      titre: json['titre'] as String? ?? '',
      description: json['description'] as String?,
      url: json['url'] as String? ?? '',
      videoUrl: json['video_url'] as String?,
      subtitleUrl: json['subtitle_url'] as String?,
      type: json['type'] as String? ?? '',
      categorie: json['categorie'] as String? ?? '',
      duree: json['duree'] as int?,
      formationId: json['formation_id'] as int? ?? 0,
      videoPlatform: json['video_platform'] as String? ?? 'server',
      videoFilePath: json['video_file_path'] as String?,
      subtitleFilePath: json['subtitle_file_path'] as String?,
      subtitleLanguage: json['subtitle_language'] as String?,
    );
  }
}