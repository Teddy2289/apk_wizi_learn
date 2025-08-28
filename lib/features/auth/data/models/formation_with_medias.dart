import 'media_model.dart';

class FormationWithMedias {
  final int id;
  final String titre;
  final List<Media> medias;

  FormationWithMedias({
    required this.id,
    required this.titre,
    required this.medias,
  });

  factory FormationWithMedias.fromJson(Map<String, dynamic> json) {
    final mediasJson = json['medias'] as List<dynamic>?;

    return FormationWithMedias(
      id: json['id'] as int? ?? 0, // Valeur par défaut si null
      titre: json['titre'] as String? ?? '', // Valeur par défaut si null
      medias: mediasJson?.map((m) => Media.fromJson(m)).toList() ?? [], // Liste vide si null
    );
  }
}