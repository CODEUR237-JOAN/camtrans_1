import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:update_camtrans/services/service_ia.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/services/service_gps.dart';
import 'package:update_camtrans/modeles/transporteur.dart';

class EtatDemandeExpedition {
  final String depart;
  final String destination;
  final double latitudeDepart;
  final double longitudeDepart;
  final double latitudeArrivee;
  final double longitudeArrivee;
  
  final String typeMarchandise;
  final String categorieVehicule;
  final String description;
  final List<XFile> photos;
  final DateTime? dateTransport;
  final TimeOfDay? heureTransport;
  
  // Sprint 10 : Nouveaux champs
  final String categorieService;
  final String optionGamme;
  final String detailsSpecifiques;
  
  // Champs spécifiques Remorque
  final String marqueVehiculeRemorque;
  final String modeleVehiculeRemorque;
  final double masseEstimeeKg;
  final bool estEnAttenteMasseIA;
  
  // Nouveaux champs pour l'IA et l'affectation
  final bool estEnAttenteIA;
  final String volumeEstime;
  final String prixEstime;
  final String conseilIA;
  final Transporteur? chauffeurPropose;
  
  final double distanceApprocheKm;
  final int tempsApprocheMin;

  EtatDemandeExpedition({
    this.depart = "",
    this.destination = "",
    this.latitudeDepart = 0.0,
    this.longitudeDepart = 0.0,
    this.latitudeArrivee = 0.0,
    this.longitudeArrivee = 0.0,
    this.typeMarchandise = "",
    this.categorieVehicule = "",
    this.description = "",
    this.photos = const [],
    this.dateTransport,
    this.heureTransport,
    this.categorieService = "",
    this.optionGamme = "",
    this.detailsSpecifiques = "",
    this.marqueVehiculeRemorque = "",
    this.modeleVehiculeRemorque = "",
    this.masseEstimeeKg = 0.0,
    this.estEnAttenteMasseIA = false,
    this.estEnAttenteIA = false,
    this.volumeEstime = "",
    this.prixEstime = "",
    this.conseilIA = "",
    this.chauffeurPropose,
    this.distanceApprocheKm = 0.0,
    this.tempsApprocheMin = 0,
  });

  bool get estValide {
    return depart.isNotEmpty &&
        destination.isNotEmpty &&
        categorieService.isNotEmpty &&
        dateTransport != null &&
        heureTransport != null;
  }

  bool estEtapeValide(int etape) {
    switch (etape) {
      case 1:
        // Pour le service Remorque, marque ET modèle sont obligatoires
        if (categorieService == "Remorque") {
          return marqueVehiculeRemorque.isNotEmpty && modeleVehiculeRemorque.isNotEmpty;
        }
        return detailsSpecifiques.isNotEmpty;
      case 2:
        return optionGamme.isNotEmpty;
      case 3:
        return depart.isNotEmpty && destination.isNotEmpty;
      default:
        return true;
    }
  }

  EtatDemandeExpedition copierAvec({
    String? depart,
    String? destination,
    double? latitudeDepart,
    double? longitudeDepart,
    double? latitudeArrivee,
    double? longitudeArrivee,
    String? typeMarchandise,
    String? categorieVehicule,
    String? description,
    List<XFile>? photos,
    DateTime? dateTransport,
    TimeOfDay? heureTransport,
    String? categorieService,
    String? optionGamme,
    String? detailsSpecifiques,
    String? marqueVehiculeRemorque,
    String? modeleVehiculeRemorque,
    double? masseEstimeeKg,
    bool? estEnAttenteMasseIA,
    bool? estEnAttenteIA,
    String? volumeEstime,
    String? prixEstime,
    String? conseilIA,
    Transporteur? chauffeurPropose,
    double? distanceApprocheKm,
    int? tempsApprocheMin,
  }) {
    return EtatDemandeExpedition(
      depart: depart ?? this.depart,
      destination: destination ?? this.destination,
      latitudeDepart: latitudeDepart ?? this.latitudeDepart,
      longitudeDepart: longitudeDepart ?? this.longitudeDepart,
      latitudeArrivee: latitudeArrivee ?? this.latitudeArrivee,
      longitudeArrivee: longitudeArrivee ?? this.longitudeArrivee,
      typeMarchandise: typeMarchandise ?? this.typeMarchandise,
      categorieVehicule: categorieVehicule ?? this.categorieVehicule,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      dateTransport: dateTransport ?? this.dateTransport,
      heureTransport: heureTransport ?? this.heureTransport,
      categorieService: categorieService ?? this.categorieService,
      optionGamme: optionGamme ?? this.optionGamme,
      detailsSpecifiques: detailsSpecifiques ?? this.detailsSpecifiques,
      marqueVehiculeRemorque: marqueVehiculeRemorque ?? this.marqueVehiculeRemorque,
      modeleVehiculeRemorque: modeleVehiculeRemorque ?? this.modeleVehiculeRemorque,
      masseEstimeeKg: masseEstimeeKg ?? this.masseEstimeeKg,
      estEnAttenteMasseIA: estEnAttenteMasseIA ?? this.estEnAttenteMasseIA,
      estEnAttenteIA: estEnAttenteIA ?? this.estEnAttenteIA,
      volumeEstime: volumeEstime ?? this.volumeEstime,
      prixEstime: prixEstime ?? this.prixEstime,
      conseilIA: conseilIA ?? this.conseilIA,
      chauffeurPropose: chauffeurPropose ?? this.chauffeurPropose,
      distanceApprocheKm: distanceApprocheKm ?? this.distanceApprocheKm,
      tempsApprocheMin: tempsApprocheMin ?? this.tempsApprocheMin,
    );
  }
}

class DemandeExpeditionNotifier extends StateNotifier<EtatDemandeExpedition> {
  final ServiceIA serviceIA;
  final ServiceFirestore serviceFirestore;
  final ServiceGps serviceGps;

  DemandeExpeditionNotifier(this.serviceIA, this.serviceFirestore, this.serviceGps) : super(EtatDemandeExpedition());

  void setDepart(String val) => state = state.copierAvec(depart: val);
  void setDestination(String val) => state = state.copierAvec(destination: val);
  void setLatitudeDepart(double val) => state = state.copierAvec(latitudeDepart: val);
  void setLongitudeDepart(double val) => state = state.copierAvec(longitudeDepart: val);
  void setLatitudeArrivee(double val) => state = state.copierAvec(latitudeArrivee: val);
  void setLongitudeArrivee(double val) => state = state.copierAvec(longitudeArrivee: val);
  
  void setTypeMarchandise(String val) => state = state.copierAvec(typeMarchandise: val);
  void setCategorieVehicule(String val) => state = state.copierAvec(categorieVehicule: val);
  void setDescription(String val) => state = state.copierAvec(description: val);
  void setDateTransport(DateTime val) => state = state.copierAvec(dateTransport: val);
  void setHeureTransport(TimeOfDay val) => state = state.copierAvec(heureTransport: val);

  // Sprint 10
  void setCategorieService(String val) => state = state.copierAvec(categorieService: val);
  void setOptionGamme(String val) => state = state.copierAvec(optionGamme: val);
  void setDetailsSpecifiques(String val) => state = state.copierAvec(detailsSpecifiques: val);

  // Remorque — setters spécifiques
  /// Alias : setMarque (correspond à setMarqueRemorque)
  void setMarque(String val) => state = state.copierAvec(marqueVehiculeRemorque: val);
  /// Alias : setModele (correspond à setModeleRemorque)
  void setModele(String val) => state = state.copierAvec(modeleVehiculeRemorque: val);
  void setMarqueRemorque(String val) => state = state.copierAvec(marqueVehiculeRemorque: val);
  void setModeleRemorque(String val) => state = state.copierAvec(modeleVehiculeRemorque: val);
  void setMasseEstimeeKg(double val) => state = state.copierAvec(masseEstimeeKg: val);
  void setEstEnAttenteMasseIA(bool val) => state = state.copierAvec(estEnAttenteMasseIA: val);

  Future<void> estimerMasseIA() async {
    if (state.marqueVehiculeRemorque.isEmpty || state.modeleVehiculeRemorque.isEmpty) return;
    state = state.copierAvec(estEnAttenteMasseIA: true);
    try {
      final masse = await serviceIA.estimerMasseVehicule(state.marqueVehiculeRemorque, state.modeleVehiculeRemorque);
      state = state.copierAvec(masseEstimeeKg: masse, estEnAttenteMasseIA: false);
    } catch (e) {
      debugPrint("Erreur estimation masse IA: $e");
      state = state.copierAvec(masseEstimeeKg: 1500.0, estEnAttenteMasseIA: false); // Fallback
    }
  }

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

  Future<void> estimerAvecIA() async {
    state = state.copierAvec(estEnAttenteIA: true);
    
    Map<String, dynamic> estimation;
    try {
      estimation = await serviceIA.estimerExpedition(
        marchandise: state.typeMarchandise.isNotEmpty ? state.typeMarchandise : state.categorieService,
        description: "${state.description}\nCatégorie: ${state.categorieService}\nGamme: ${state.optionGamme}\nDétails: ${state.detailsSpecifiques}",
        depart: state.depart,
        destination: state.destination,
        fichiersImages: state.photos,
      );
    } catch (e) {
      debugPrint("️ IA Indisponible (Quota/Erreur), utilisation du fallback : $e");
      final vehiculeParDefaut = state.categorieService == 'Remorque' 
          ? "Dépanneuse" 
          : (state.categorieVehicule.isNotEmpty ? state.categorieVehicule : "Camionnette");
          
      estimation = {
        "vehicule": vehiculeParDefaut,
        "volume": "Selon chargement",
        "prix": "Sur devis",
        "conseil": "Le système d'analyse est temporairement saturé. Un conseiller vérifiera vos détails.",
      };
    }

    // Géocodage si le client a tapé l'adresse manuellement sans utiliser le GPS
    double latClient = state.latitudeDepart;
    // lngClient est utilisé ci-dessous pour mettre à jour l'état
    double lngClient = state.longitudeDepart;

      if (latClient == 0.0 && state.depart.isNotEmpty) {
        try {
          final loc = await serviceGps.obtenirCoordonnees(state.depart);
          if (loc != null) {
            latClient = loc.latitude;
            lngClient = loc.longitude;
          }
        } catch (_) {}
      }

      // Utilisation de lngClient pour éviter le warning
      state = state.copierAvec(latitudeDepart: latClient, longitudeDepart: lngClient);
      Transporteur? chauffeur;
      try {
        // Règle métier absolue : si c'est une remorque, c'est TOUJOURS une Dépanneuse, peu importe ce que dit l'IA.
        final vehiculeRequis = state.categorieService == 'Remorque' 
            ? "Dépanneuse" 
            : (estimation["vehicule"] ?? state.categorieVehicule);
        
        // On récupère TOUS les transporteurs en ligne pour debugger
        final query = await serviceFirestore.transporteurs
            .where('estEnLigne', isEqualTo: true)
            .get();
        
        List<Transporteur> candidats = [];
        debugPrint("🔍 RECHERCHE DE CHAUFFEUR : ${query.docs.length} transporteur(s) en ligne trouvé(s). Véhicule requis = '$vehiculeRequis'");
        
        for (var doc in query.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          final t = Transporteur.fromMap(data);
          
          debugPrint("   👉 Analyse de ${t.prenom} ${t.nom} (ID: ${t.id}) :");
          debugPrint("      - estEnLigne: ${t.estEnLigne}");
          debugPrint("      - disponible: ${t.disponible}");
          debugPrint("      - documentsValides: ${t.documentsValides}");
          debugPrint("      - typeVehicule: '${t.typeVehicule}' (Requis: '$vehiculeRequis')");
          
          // Filtrage rigoureux en mémoire
          if (t.estEnLigne && t.disponible && t.documentsValides && t.typeVehicule == vehiculeRequis) {
            candidats.add(t);
            debugPrint("      ✅ ACCEPTE comme candidat !");
          } else {
            debugPrint("      ❌ REJETE.");
          }
        }
        
        // Règle d'équité CamTrans : Priorité au transporteur ayant le moins de courses
        if (candidats.isNotEmpty) {
           candidats.sort((a, b) => a.nombreCourses.compareTo(b.nombreCourses));
           chauffeur = candidats.first;
           debugPrint("🏆 Chauffeur sélectionné : ${chauffeur.prenom} ${chauffeur.nom}");
        } else {
           debugPrint("⚠️ Aucun candidat n'a passé tous les filtres.");
        }
      } catch (e) {
        debugPrint("Erreur lors de la recherche du chauffeur: $e");
      }

      state = state.copierAvec(
        estEnAttenteIA: false,
        categorieVehicule: estimation["vehicule"],
        volumeEstime: estimation["volume"],
        prixEstime: estimation["prix"],
        conseilIA: estimation["conseil"],
        chauffeurPropose: chauffeur,
      );
  }
}

final demandeExpeditionProvider =
    StateNotifierProvider<DemandeExpeditionNotifier, EtatDemandeExpedition>((
      ref,
    ) {
  final service = ref.watch(serviceIAProvider);
  final firestore = ref.watch(serviceFirestoreProvider);
  final gps = ref.watch(serviceGpsProvider);
  return DemandeExpeditionNotifier(service, firestore, gps);
});

// Cleanup useless inner class

