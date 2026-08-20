import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:update_camtrans/services/service_ia.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/services/service_gps.dart';
import 'package:update_camtrans/services/service_notification.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';

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
        return categorieService.isNotEmpty;
      case 2:
        // Pour le service Remorque, marque ET modèle sont obligatoires
        if (categorieService == "Remorque") {
          return marqueVehiculeRemorque.isNotEmpty && modeleVehiculeRemorque.isNotEmpty;
        }
        return detailsSpecifiques.isNotEmpty;
      case 3:
        return optionGamme.isNotEmpty;
      case 4:
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

  double _calculerDistanceHaversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Rayon de la Terre en km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
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
      debugPrint("⚠️ IA Indisponible (Quota/Erreur), utilisation du fallback : $e");
      estimation = {
        "vehicule": state.categorieVehicule.isNotEmpty ? state.categorieVehicule : "Camionnette",
        "volume": "Selon chargement",
        "prix": "Sur devis",
        "conseil": "L'assistant IA est temporairement saturé. Un conseiller vérifiera vos détails.",
      };
    }

    // Géocodage si le client a tapé l'adresse manuellement sans utiliser le GPS
    double latClient = state.latitudeDepart;
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

      // ═══════════════════════════════════════════════════════
      // ALGORITHME DE MATCHING (version corrigée)
      // Conditions OBLIGATOIRES pour qu'un transporteur soit éligible :
      //   1. disponible = true  (il s'est mis en ligne)
      //   2. actif = true       (vérifié / validé par l'admin)
      //   3. documentsValides = true (documents acceptés)
      //   4. Véhicule adapté à la catégorie de service demandée
      //   5. Aucune course active en cours
      // Puis on trie par distance Haversine (si GPS disponible),
      // sinon on fait un tirage aléatoire équitable.
      // ═══════════════════════════════════════════════════════
      Transporteur? meilleurChauffeur;
      double distanceMin = double.infinity;
      int tempsMin = 0;

      try {
        // Étape 1 : Récupérer tous les transporteurs en ligne, actifs et validés
        final query = await serviceFirestore.transporteurs
            .where("disponible", isEqualTo: true)
            .where("actif", isEqualTo: true)
            .get();

        // Étape 2 : Récupérer les IDs des transporteurs ayant une course active
        // On cherche les courses avec statut actif (non terminées)
        final coursesActives = await serviceFirestore.courses
            .where("statut", whereIn: [
              StatutCourse.attribue,
              StatutCourse.enRouteDepart,
              StatutCourse.arriveDepart,
              StatutCourse.charge,
              StatutCourse.enTransit,
              StatutCourse.arriveDestination,
            ])
            .get();
        final transporteursOccupes = <String>{
          for (var doc in coursesActives.docs)
            if ((doc.data()["transporteurId"] ?? "").toString().isNotEmpty)
              doc.data()["transporteurId"] as String,
        };

        // Étape 3 : Filtrer les candidats éligibles
        final List<_CandidatTransporteur> candidats = [];

        for (var doc in query.docs) {
          final t = Transporteur.fromMap(doc.data());

          // Vérification: documents validés par l'admin
          if (!t.documentsValides) continue;

          // Vérification: pas de course active en cours
          if (transporteursOccupes.contains(t.id)) continue;

          // Vérification du type de véhicule (insensible à la casse)
          final typeV = t.typeVehicule.toLowerCase().trim();
          bool vehiculeCompatible = false;

          if (typeV.isEmpty) {
            // Type non renseigné → fallback accepté uniquement pour Marchandises
            vehiculeCompatible = state.categorieService != "Remorque";
          } else if (state.categorieService == "Remorque") {
            // UNIQUEMENT dépanneuse / semi-remorque pour Remorque
            vehiculeCompatible = typeV.contains("depanneuse") ||
                typeV.contains("dépanneuse") ||
                typeV.contains("semi-remorque") ||
                typeV.contains("semi_remorque") ||
                typeV.contains("remorque");
          } else if (state.categorieService == "Déménagement") {
            vehiculeCompatible = typeV.contains("camion") ||
                typeV.contains("fourgon") ||
                typeV.contains("van") ||
                typeV.contains("semi");
          } else {
            // Marchandises : aligner sur la recommandation IA ou le choix client
            final reqV = (estimation["vehicule"] ?? state.categorieVehicule)
                .toString()
                .toLowerCase()
                .trim();
            if (reqV.isEmpty) {
              vehiculeCompatible = true;
            } else if (reqV.contains("moto")) {
              vehiculeCompatible = typeV.contains("moto");
            } else if (reqV.contains("camion") || reqV.contains("fourgon")) {
              vehiculeCompatible = typeV.contains("camion") ||
                  typeV.contains("fourgon") ||
                  typeV.contains("van");
            } else if (reqV.contains("voiture") || reqV.contains("berline")) {
              vehiculeCompatible = typeV.contains("voiture") ||
                  typeV.contains("berline") ||
                  typeV.contains("sedan");
            } else {
              vehiculeCompatible = typeV.contains(reqV) || reqV.contains(typeV);
            }
          }

          if (!vehiculeCompatible) continue;

          // Calculer distance si GPS disponible
          double distCandidat = double.infinity;
          if (latClient != 0.0 &&
              lngClient != 0.0 &&
              t.latitude != 0 &&
              t.longitude != 0) {
            distCandidat = _calculerDistanceHaversine(
                latClient, lngClient, t.latitude, t.longitude);
          }

          candidats.add(_CandidatTransporteur(transporteur: t, distance: distCandidat));
        }

        // Étape 4 : Sélectionner le meilleur candidat
        if (candidats.isNotEmpty) {
          final avecGPS =
              candidats.where((c) => c.distance != double.infinity).toList();

          if (avecGPS.isNotEmpty) {
            // GPS disponible → prendre le plus proche
            avecGPS.sort((a, b) => a.distance.compareTo(b.distance));
            final meilleur = avecGPS.first;
            meilleurChauffeur = meilleur.transporteur;
            distanceMin = meilleur.distance;
            tempsMin = (distanceMin / 40 * 60).round();
          } else {
            // GPS indisponible → tirage aléatoire équitable (rotation)
            candidats.shuffle(Random());
            meilleurChauffeur = candidats.first.transporteur;
            distanceMin = 5.0;
            tempsMin = 8;
          }
        }
      } catch (e) {
        debugPrint("Erreur matching chauffeur: $e");
      }


      state = state.copierAvec(
        estEnAttenteIA: false,
        categorieVehicule: estimation["vehicule"],
        volumeEstime: estimation["volume"],
        prixEstime: estimation["prix"],
        conseilIA: estimation["conseil"],
        chauffeurPropose: meilleurChauffeur,
        distanceApprocheKm: distanceMin == double.infinity ? 0 : distanceMin,
        tempsApprocheMin: tempsMin,
      );

      // Notification Autonome Simulée (Sprint 12)
      if (meilleurChauffeur != null) {
        ServiceNotification.afficherNotification(
          titre: "🚕 Transporteur trouvé !",
          message: "Le chauffeur ${meilleurChauffeur.prenom} a accepté votre course et se trouve à $tempsMin min.",
        );
      }
  }
}

final demandeExpeditionProvider =
    StateNotifierProvider.autoDispose<DemandeExpeditionNotifier, EtatDemandeExpedition>((ref) {
  final service = ref.watch(serviceIAProvider);
  final firestore = ref.watch(serviceFirestoreProvider);
  final gps = ref.watch(serviceGpsProvider);
  return DemandeExpeditionNotifier(service, firestore, gps);
});

/// Classe utilitaire interne pour trier les candidats lors du matching
class _CandidatTransporteur {
  final Transporteur transporteur;
  final double distance; // en km ; double.infinity si GPS indisponible

  const _CandidatTransporteur({
    required this.transporteur,
    required this.distance,
  });
}
