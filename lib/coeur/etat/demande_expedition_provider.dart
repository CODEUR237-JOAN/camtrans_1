import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/service_ia.dart';
import '../../services/service_firestore.dart';
import '../../modeles/transporteur.dart';

class EtatDemandeExpedition {
  final String depart;
  final String destination;
  final String typeMarchandise;
  final String categorieVehicule;
  final String description;
  final List<XFile> photos;
  final DateTime? dateTransport;
  final TimeOfDay? heureTransport;
  
  // Nouveaux champs pour l'IA et l'affectation
  final bool estEnAttenteIA;
  final String volumeEstime;
  final String prixEstime;
  final String conseilIA;
  final Transporteur? chauffeurPropose;

  EtatDemandeExpedition({
    this.depart = "",
    this.destination = "",
    this.typeMarchandise = "",
    this.categorieVehicule = "",
    this.description = "",
    this.photos = const [],
    this.dateTransport,
    this.heureTransport,
    this.estEnAttenteIA = false,
    this.volumeEstime = "",
    this.prixEstime = "",
    this.conseilIA = "",
    this.chauffeurPropose,
  });

  bool get estValide {
    return depart.isNotEmpty &&
        destination.isNotEmpty &&
        typeMarchandise.isNotEmpty &&
        categorieVehicule.isNotEmpty &&
        dateTransport != null &&
        heureTransport != null;
  }

  EtatDemandeExpedition copierAvec({
    String? depart,
    String? destination,
    String? typeMarchandise,
    String? categorieVehicule,
    String? description,
    List<XFile>? photos,
    DateTime? dateTransport,
    TimeOfDay? heureTransport,
    bool? estEnAttenteIA,
    String? volumeEstime,
    String? prixEstime,
    String? conseilIA,
    Transporteur? chauffeurPropose,
  }) {
    return EtatDemandeExpedition(
      depart: depart ?? this.depart,
      destination: destination ?? this.destination,
      typeMarchandise: typeMarchandise ?? this.typeMarchandise,
      categorieVehicule: categorieVehicule ?? this.categorieVehicule,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      dateTransport: dateTransport ?? this.dateTransport,
      heureTransport: heureTransport ?? this.heureTransport,
      estEnAttenteIA: estEnAttenteIA ?? this.estEnAttenteIA,
      volumeEstime: volumeEstime ?? this.volumeEstime,
      prixEstime: prixEstime ?? this.prixEstime,
      conseilIA: conseilIA ?? this.conseilIA,
      chauffeurPropose: chauffeurPropose ?? this.chauffeurPropose,
    );
  }
}


class DemandeExpeditionNotifier extends StateNotifier<EtatDemandeExpedition> {
  final ServiceIA serviceIA;
  final ServiceFirestore serviceFirestore;
  DemandeExpeditionNotifier(this.serviceIA, this.serviceFirestore) : super(EtatDemandeExpedition());

  void setDepart(String val) => state = state.copierAvec(depart: val);
  void setDestination(String val) => state = state.copierAvec(destination: val);
  void setTypeMarchandise(String val) => state = state.copierAvec(typeMarchandise: val);
  void setCategorieVehicule(String val) => state = state.copierAvec(categorieVehicule: val);
  void setDescription(String val) => state = state.copierAvec(description: val);
  void setDateTransport(DateTime val) => state = state.copierAvec(dateTransport: val);
  void setHeureTransport(TimeOfDay val) => state = state.copierAvec(heureTransport: val);

  Future<void> ajouterPhotos() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      state = state.copierAvec(photos: [...state.photos, ...images]);
      // Déclenche l'analyse IA visuelle automatiquement en arrière-plan
      estimerAvecIA();
    }
  }

  void supprimerPhoto(int index) {
    final nouvellesPhotos = List<XFile>.from(state.photos)..removeAt(index);
    state = state.copierAvec(photos: nouvellesPhotos);
  }

  void reinitialiser() {
    state = EtatDemandeExpedition();
  }

  Future<void> estimerAvecIA() async {
    if (state.photos.isEmpty && state.description.isEmpty) {
      return; // On a besoin d'au moins une photo ou une description
    }

    state = state.copierAvec(estEnAttenteIA: true);
    try {
      final estimation = await serviceIA.estimerExpedition(
        marchandise: state.typeMarchandise,
        description: state.description,
        depart: state.depart,
        destination: state.destination,
        cheminsImages: state.photos.map((p) => p.path).toList(),
      );

      // Récupérer un chauffeur disponible au hasard (le premier trouvé)
      Transporteur? chauffeur;
      try {
        final query = await serviceFirestore.transporteurs
            .where("disponible", isEqualTo: true)
            .where("documentsValides", isEqualTo: true)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          chauffeur = Transporteur.fromMap(query.docs.first.data());
        }
      } catch (_) {}

      state = state.copierAvec(
        estEnAttenteIA: false,
        categorieVehicule: estimation["vehicule"],
        volumeEstime: estimation["volume"],
        prixEstime: estimation["prix"],
        conseilIA: estimation["conseil"],
        chauffeurPropose: chauffeur,
      );
    } catch (e) {
      state = state.copierAvec(
        estEnAttenteIA: false,
        conseilIA: "Impossible d'obtenir une estimation pour le moment.",
      );
    }
  }
}

final demandeExpeditionProvider =
    StateNotifierProvider.autoDispose<DemandeExpeditionNotifier, EtatDemandeExpedition>((ref) {
  final service = ref.watch(serviceIAProvider);
  final firestore = ref.watch(serviceFirestoreProvider);
  return DemandeExpeditionNotifier(service, firestore);
});
