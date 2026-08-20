import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:update_camtrans/modeles/message_ia.dart';
import 'package:update_camtrans/services/service_ia.dart';

class IAState {
  final List<MessageIA> messages;
  final bool enReponse;

  IAState({this.messages = const [], this.enReponse = false});

  IAState copierAvec({List<MessageIA>? messages, bool? enReponse}) {
    return IAState(
      messages: messages ?? this.messages,
      enReponse: enReponse ?? this.enReponse,
    );
  }
}

class IANotifier extends StateNotifier<IAState> {
  final ServiceIA _serviceIA;

  IANotifier(this._serviceIA) : super(IAState());

  void ajouterMessageUtilisateur(String texte, {List<XFile>? fichiersImages}) {
    final msgU = MessageIA(
      texte: texte,
      estUtilisateur: true,
      piecesJointes: fichiersImages ?? [],
    );
    state = state.copierAvec(messages: [...state.messages, msgU], enReponse: true);

    _demanderReponseIA(texte, fichiersImages);
  }

  void _demanderReponseIA(String prompt, List<XFile>? fichiersImages) async {
    // Créer une coquille vide pour le message de l'IA
    final msgIA = MessageIA(
      texte: "",
      estUtilisateur: false,
      estEnChargement: true,
    );
    
    // L'ajouter à la liste
    state = state.copierAvec(messages: [...state.messages, msgIA]);
    
    final msgId = msgIA.id;
    String texteAccumule = "";

    try {
      final stream = _serviceIA.envoyerMessageStream(prompt, fichiersImages: fichiersImages);

      await for (final chunk in stream) {
        texteAccumule += chunk;
        
        // Mettre à jour le message spécifique dans la liste
        final index = state.messages.indexWhere((m) => m.id == msgId);
        if (index != -1) {
          final listeMiseAJour = List<MessageIA>.from(state.messages);
          listeMiseAJour[index] = listeMiseAJour[index].copierAvec(
            texte: texteAccumule,
            estEnChargement: false,
          );
          state = state.copierAvec(messages: listeMiseAJour);
        }
      }
    } catch (e) {
      final index = state.messages.indexWhere((m) => m.id == msgId);
      if (index != -1) {
        final listeMiseAJour = List<MessageIA>.from(state.messages);
        listeMiseAJour[index] = listeMiseAJour[index].copierAvec(
          texte: "Une erreur est survenue lors de la communication avec l'IA.",
          estEnChargement: false,
        );
        state = state.copierAvec(messages: listeMiseAJour);
      }
    } finally {
      state = state.copierAvec(enReponse: false);
    }
  }

  void effacerHistorique() {
    state = IAState();
  }
}

final iaProvider = StateNotifierProvider<IANotifier, IAState>((ref) {
  return IANotifier(ref.read(serviceIAProvider));
});
