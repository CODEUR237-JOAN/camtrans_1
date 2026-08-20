import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

class MessageIA {
  final String id;
  final String texte;
  final bool estUtilisateur;
  final DateTime dateCreation;
  final List<XFile> piecesJointes; // Fichiers/images (XFile pour compatibilité Web/Mobile)
  final bool estEnChargement;

  MessageIA({
    String? id,
    required this.texte,
    required this.estUtilisateur,
    DateTime? dateCreation,
    this.piecesJointes = const [],
    this.estEnChargement = false,
  })  : id = id ?? const Uuid().v4(),
        dateCreation = dateCreation ?? DateTime.now();

  MessageIA copierAvec({
    String? texte,
    bool? estUtilisateur,
    List<XFile>? piecesJointes,
    bool? estEnChargement,
  }) {
    return MessageIA(
      id: id,
      texte: texte ?? this.texte,
      estUtilisateur: estUtilisateur ?? this.estUtilisateur,
      dateCreation: dateCreation,
      piecesJointes: piecesJointes ?? this.piecesJointes,
      estEnChargement: estEnChargement ?? this.estEnChargement,
    );
  }
}
