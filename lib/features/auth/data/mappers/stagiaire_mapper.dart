import 'package:wizi_learn/features/auth/domain/stagiaire_entity.dart';
import '../models/stagiaire_model.dart';

class StagiaireMapper {
  static StagiaireEntity toEntity(StagiaireModel model) {
    return StagiaireEntity(
      id: model.id,
      prenom: model.prenom,
      civilite: model.civilite,
      telephone: model.telephone,
      adresse: model.adresse,
      dateNaissance: model.dateNaissance,
      ville: model.ville,
      codePostal: model.codePostal,
      dateDebutFormation: model.dateDebutFormation,
      dateInscription: model.dateInscription,
      role: model.role,
      statut: model.statut,
      userId: model.userId,
    );
  }

  static StagiaireModel toModel(StagiaireEntity entity) {
    return StagiaireModel(
      id: entity.id,
      prenom: entity.prenom,
      civilite: entity.civilite,
      telephone: entity.telephone,
      adresse: entity.adresse,
      dateNaissance: entity.dateNaissance,
      ville: entity.ville,
      codePostal: entity.codePostal,
      dateDebutFormation: entity.dateDebutFormation,
      dateFinFormation: '',
      dateInscription: entity.dateInscription,
      role: entity.role,
      statut: entity.statut,
      userId: entity.userId,
    );
  }
}
