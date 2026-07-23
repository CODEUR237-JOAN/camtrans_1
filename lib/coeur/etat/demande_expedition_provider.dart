import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class EtatDemandeExpedition {
  final String depart;
  final String destination;
  final String typeMarchandise;
  final String categorieVehicule;
  final String description;
  final List<XFile> photos;
  final DateTime? dateTransport;
  final TimeOfDay? heureTransport;

  EtatDemandeExpedition({
    this.depart = "",
    this.destination = "",
    this.typeMarchandise = "",
    this.categorieVehicule = "",
    this.description = "",
    this.photos = const [],
    this.dateTransport,
    this.heureTransport,
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
    );
  }
}

class DemandeExpeditionNotifier extends StateNotifier<EtatDemandeExpedition> {
  DemandeExpeditionNotifier() : super(EtatDemandeExpedition());

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
    }
  }

  void supprimerPhoto(int index) {
    final nouvellesPhotos = List<XFile>.from(state.photos)..removeAt(index);
    state = state.copierAvec(photos: nouvellesPhotos);
  }

  void reinitialiser() {
    state = EtatDemandeExpedition();
  }
}

final demandeExpeditionProvider =
    StateNotifierProvider<DemandeExpeditionNotifier, EtatDemandeExpedition>((ref) {
  return DemandeExpeditionNotifier();
});
