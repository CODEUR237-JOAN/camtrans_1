import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:update_camtrans/coeur/etat/demande_expedition_provider.dart';
import 'package:update_camtrans/coeur/etat/estimation_provider.dart';
import 'package:update_camtrans/coeur/etat/course_provider.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_gps.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'carte_estimation.dart';
import 'recherche_radar.dart';
import 'carte_estimation_remorque.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

class ResumeExpeditionBottomSheet extends ConsumerStatefulWidget {
  const ResumeExpeditionBottomSheet({super.key});

  @override
  ConsumerState<ResumeExpeditionBottomSheet> createState() => _ResumeExpeditionBottomSheetState();
}

class _ResumeExpeditionBottomSheetState extends ConsumerState<ResumeExpeditionBottomSheet> {
  @override
  void initState() {
    super.initState();
    // Lancer l'estimation dès l'ouverture de la BottomSheet
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final etatDemande = ref.read(demandeExpeditionProvider);
      
      double distanceKm = 10.0;
      final serviceGps = ref.read(serviceGpsProvider);
      final locDepart = await serviceGps.obtenirCoordonnees(etatDemande.depart);
      final locArrivee = await serviceGps.obtenirCoordonnees(etatDemande.destination);
      if (locDepart != null && locArrivee != null) {
        distanceKm = serviceGps.calculerDistance(
          latitudeDepart: locDepart.latitude,
          longitudeDepart: locDepart.longitude,
          latitudeArrivee: locArrivee.latitude,
          longitudeArrivee: locArrivee.longitude,
        );
      }

      ref.read(estimationProvider.notifier).lancerEstimation(
        depart: etatDemande.depart,
        arrivee: etatDemande.destination,
        typeMarchandise: etatDemande.typeMarchandise,
        description: etatDemande.description,
        categorieVehicule: etatDemande.categorieVehicule,
        isRemorque: etatDemande.categorieService == "Remorque",
        masseRemorqueKg: etatDemande.masseEstimeeKg,
        distanceKm: distanceKm,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(demandeExpeditionProvider);
    final etatEstimation = ref.watch(estimationProvider);

    Widget content = Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      margin: etat.categorieService == "Remorque" ? const EdgeInsets.all(16) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: const Color(0xFF08111F).withValues(alpha: 0.95),
        borderRadius: etat.categorieService == "Remorque" ? BorderRadius.circular(24.0) : const BorderRadius.vertical(top: Radius.circular(24.0)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: -5)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre de défilement visuelle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Résumé de l'expédition",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  _buildInfoRow(context, Iconsax.location_copy, "Trajet", "${etat.depart}  ${etat.destination}"),
                  const SizedBox(height: 16),
                  _buildInfoRow(context, Iconsax.category_copy, "Service", "${etat.categorieService} (Gamme ${etat.optionGamme})"),
                  const SizedBox(height: 16),
                  // Pour Remorque : afficher le type du chauffeur assigné, pas l'estimation IA
                  _buildInfoRow(
                    context,
                    Iconsax.truck_fast_copy,
                    "Véhicule",
                    etat.categorieService == "Remorque"
                        ? (etat.chauffeurPropose?.typeVehicule.isNotEmpty == true
                            ? etat.chauffeurPropose!.typeVehicule
                            : "Dépanneuse")
                        : etat.categorieVehicule.isNotEmpty
                            ? etat.categorieVehicule
                            : "Adapté à votre charge",
                  ),
                  const SizedBox(height: 16),
                  if (etat.chauffeurPropose != null) ...[
                    _buildInfoRow(
                      context,
                      Iconsax.user_copy,
                      "Chauffeur assigné",
                      "${etat.chauffeurPropose!.prenom} ${etat.chauffeurPropose!.nom} · ${etat.chauffeurPropose!.typeVehicule.isNotEmpty ? etat.chauffeurPropose!.typeVehicule : 'Transporteur'} · ${etat.distanceApprocheKm.toStringAsFixed(1)} km",
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (etat.dateTransport != null && etat.heureTransport != null)
                    _buildInfoRow(
                      context,
                      Iconsax.calendar_1_copy,
                      "Date de la demande",
                      "${DateFormat('dd/MM/yyyy').format(etat.dateTransport!)} à ${etat.heureTransport!.format(context)} (Immédiat)",
                    ),
                  if (etat.detailsSpecifiques.isNotEmpty || etat.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow(context, Iconsax.textalign_left_copy, "Détails", etat.detailsSpecifiques.isNotEmpty ? etat.detailsSpecifiques : etat.description),
                  ],
                  if (etat.photos.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      "Photos (${etat.photos.length})",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: etat.photos.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb 
                              ? Image.network(
                                  etat.photos[index].path,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  io.File(etat.photos[index].path),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Affichage du module d'estimation
                  if (etatEstimation.enCours)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: LoaderPremium(size: 24),
                    ))
                  else if (etatEstimation.erreur != null)
                    Text("Oups ! Un petit imprévu : ${etatEstimation.erreur} 🔧", style: const TextStyle(color: Colors.red))
                  else if (etatEstimation.resultat != null)
                    Column(
                      children: [
                        etat.categorieService == "Remorque"
                          ? CarteEstimationRemorque(
                              resultat: etatEstimation.resultat!,
                              marque: etat.marqueVehiculeRemorque,
                              modele: etat.modeleVehiculeRemorque,
                              masseKg: etat.masseEstimeeKg,
                              latitudeDepart: etat.latitudeDepart,
                              longitudeDepart: etat.longitudeDepart,
                              latitudeArrivee: etat.latitudeArrivee,
                              longitudeArrivee: etat.longitudeArrivee,
                            )
                          : CarteEstimationIntelligente(resultat: etatEstimation.resultat!),
                          
                        const SizedBox(height: 16),
                        
                        // Badge de Tarification Standardisée
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: CouleursApp.succes.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CouleursApp.succes.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified, color: CouleursApp.succes, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Tarif Standardisé CamTrans",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: CouleursApp.succes),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Calculé équitablement selon la distance et le volume. Sans négociation.",
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: etat.categorieService == "Remorque"
                    ? const LinearGradient(
                        colors: [CouleursApp.succes, Color(0xFF0E9456)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                boxShadow: [
                  BoxShadow(
                    color: etat.categorieService == "Remorque"
                        ? CouleursApp.succes.withValues(alpha: 0.35)
                        : const Color(0xFF3B82F6).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final user = ref.read(serviceAuthentificationProvider).utilisateur;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Hmm, il semblerait que vous ne soyez pas connecté. 🤔")),
                    );
                    return;
                  }

                  final courseActive = ref.read(activeCourseClientProvider);
                  if (courseActive != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Vous avez déjà une expédition en cours."),
                        backgroundColor: CouleursApp.erreur,
                      ),
                    );
                    return;
                  }


                  // Afficher le Radar pendant l'affectation
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: false,
                    pageBuilder: (ctx, a1, a2) => const RechercheRadar(),
                  );
                  await Future.delayed(const Duration(seconds: 3));

                  try {
                    final String courseId = 'course_${const Uuid().v4()}';
                    final List<String> photosUrl = [];

                    final serviceGps = ref.read(serviceGpsProvider);
                    final locDepart = await serviceGps.obtenirCoordonnees(etat.depart);
                    final locArrivee = await serviceGps.obtenirCoordonnees(etat.destination);

                    final double latDepart = locDepart?.latitude ?? 0.0;
                    final double lngDepart = locDepart?.longitude ?? 0.0;
                    final double latArrivee = locArrivee?.latitude ?? 0.0;
                    final double lngArrivee = locArrivee?.longitude ?? 0.0;

                    double distanceKm = 0.0;
                    if (latDepart != 0 && latArrivee != 0) {
                      distanceKm = serviceGps.calculerDistance(
                        latitudeDepart: latDepart,
                        longitudeDepart: lngDepart,
                        latitudeArrivee: latArrivee,
                        longitudeArrivee: lngArrivee,
                      );
                    }

                    // ✅ PHASE 4: ALGORTIHME DE DISPATCH - Recherche des transporteurs à proximité
                    final typeVehiculeRequis = etatEstimation.resultat?.vehiculeRecommande ?? etat.categorieVehicule;
                    
                    // 1. Récupérer tous les transporteurs en ligne et valides
                    final transporteursSnap = await FirebaseFirestore.instance
                        .collection('transporteurs')
                        .where('disponible', isEqualTo: true)
                        .where('documentsValides', isEqualTo: true)
                        .get();
                        
                    // 2. Filtrer par type de véhicule et calculer la distance au départ
                    final List<Map<String, dynamic>> candidatsDispo = [];
                    for (var doc in transporteursSnap.docs) {
                      final t = doc.data();
                      // Filtrer type
                      if (typeVehiculeRequis.isNotEmpty && t['typeVehicule'] != typeVehiculeRequis) continue;
                      
                      final double tLat = t['latitude'] ?? 0.0;
                      final double tLng = t['longitude'] ?? 0.0;
                      
                      if (tLat != 0.0) {
                        final dist = serviceGps.calculerDistance(
                          latitudeDepart: latDepart, longitudeDepart: lngDepart,
                          latitudeArrivee: tLat, longitudeArrivee: tLng,
                        );
                        final int nbCourses = t['nombreCourses'] ?? 0;
                        candidatsDispo.add({'id': doc.id, 'distance': dist, 'nom': t['prenom'], 'nombreCourses': nbCourses});
                      } else {
                        // S'il n'a pas de GPS, on le met loin par défaut
                        final int nbCourses = t['nombreCourses'] ?? 0;
                        candidatsDispo.add({'id': doc.id, 'distance': 9999.0, 'nom': t['prenom'], 'nombreCourses': nbCourses});
                      }
                    }
                    
                    // 3. Trier avec équité : Distance d'abord, mais si la différence est faible (< 3 km), prioriser celui avec le moins de courses.
                    candidatsDispo.sort((a, b) {
                      final distA = a['distance'] as double;
                      final distB = b['distance'] as double;
                      final coursesA = a['nombreCourses'] as int;
                      final coursesB = b['nombreCourses'] as int;

                      // Si les deux transporteurs sont proches de la course (ex: à moins de 3km l'un de l'autre)
                      if ((distA - distB).abs() <= 3.0) {
                        // Si A a au moins 2 courses de plus que B, on choisit B (équité)
                        if (coursesA - coursesB >= 2) return 1;
                        // Si B a au moins 2 courses de plus que A, on choisit A
                        if (coursesB - coursesA >= 2) return -1;
                      }

                      // Sinon, tri standard par distance
                      return distA.compareTo(distB);
                    });
                    
                    // 4. Extraire uniquement les IDs
                    final List<String> candidatsFinaux = candidatsDispo.map((e) => e['id'] as String).toList();
                    
                    // Si un chauffeur avait été spécifiquement proposé par le client, on le met en premier (priorité)
                    if (etat.chauffeurPropose != null) {
                      candidatsFinaux.remove(etat.chauffeurPropose!.id);
                      candidatsFinaux.insert(0, etat.chauffeurPropose!.id);
                    }
                    
                    // 5. Déterminer le statut initial de la course
                    String statutInitial = StatutCourse.recherche;
                    String premierTransporteurId = '';
                    DateTime? expiration;
                    
                    if (candidatsFinaux.isNotEmpty) {
                      statutInitial = StatutCourse.propose;
                      premierTransporteurId = candidatsFinaux.first;
                      expiration = DateTime.now().add(const Duration(seconds: 30));
                      // (Le nom/tel du transporteur reste vide jusqu'à ce qu'il accepte vraiment)
                    }

                    // Générer un code PIN à 4 chiffres
                    final String pin = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
                    
                    // Prix final imposé par le système (IA)
                    final double prixImpose = etatEstimation.resultat?.coutTotal ?? 0.0;

                    final course = Course(
                      id: courseId,
                      clientId: user.uid,
                      transporteurId: premierTransporteurId, // Attribué provisoirement
                      nomClient: user.displayName ?? "Client Anonyme",
                      nomTransporteur: '',
                      telephoneClient: '',
                      telephoneTransporteur: '',
                      adresseDepart: etat.depart,
                      adresseArrivee: etat.destination,
                      latitudeDepart: latDepart,
                      longitudeDepart: lngDepart,
                      latitudeArrivee: latArrivee,
                      longitudeArrivee: lngArrivee,
                      distanceKm: distanceKm,
                      volumeM3: etatEstimation.resultat?.volumeM3 ?? 0.0,
                      poidsKg: 0.0,
                      typeVehicule: typeVehiculeRequis,
                      typeMarchandise: etat.typeMarchandise.isNotEmpty ? etat.typeMarchandise : etat.categorieService,
                      prixEstime: prixImpose,
                      prixFinal: 0.0,
                      modePaiement: '',
                      paiementEffectue: false,
                      statut: statutInitial,
                      description: etat.description,
                      photos: photosUrl,
                      dateCreation: DateTime.now(),
                      dateDebut: etat.dateTransport,
                      fragile: false,
                      aideChargement: etat.optionGamme == "Confort",
                      aideDechargement: false,
                      codeSuivi: 'CMR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                      noteClient: 0.0,
                      noteTransporteur: 0.0,
                      commentaireClient: '',
                      commentaireTransporteur: '',
                      scoreIA: 0.0,
                      vehiculeRecommandeIA: etatEstimation.resultat?.vehiculeRecommande ?? '',
                      volumeEstimeIA: etatEstimation.resultat?.volumeM3 ?? 0.0,
                      conseilIA: '',
                      categorieService: etat.categorieService,
                      optionGamme: etat.optionGamme,
                      detailsSpecifiques: etat.detailsSpecifiques,
                      distanceApprocheKm: etat.distanceApprocheKm,
                      tempsApprocheMin: etat.tempsApprocheMin,
                      candidats: candidatsFinaux,
                      indexCandidatActuel: 0,
                      expirationProposition: expiration,
                      codePinLivraison: pin,
                      fondsDebloques: false,
                    );

                    await ref.read(serviceFirestoreProvider).ajouterDocument(
                      collection: 'courses',
                      id: course.id,
                      donnees: course.toMap(),
                    );
                    
                    // ✅ PHASE 4: DISPATCH - Déclencher la notification Push
                    if (premierTransporteurId.isNotEmpty) {
                      try {
                        await ref.read(serviceFirestoreProvider).ajouterDocument(
                          collection: 'notifications_push',
                          id: 'notif_${const Uuid().v4()}',
                          donnees: {
                            'titre': '🚨 NOUVELLE COURSE !',
                            'message': 'Course à ${distanceKm.toStringAsFixed(1)} km. Acceptez vite !',
                            'cible': 'transporteur',
                            'cibleId': premierTransporteurId,
                            'status': 'pending',
                            'createdAt': FieldValue.serverTimestamp(),
                          }
                        );
                      } catch (e) {
                        debugPrint("Erreur notification push ignorée : $e");
                      }
                    }

                    if (context.mounted) {
                      Navigator.pop(context); // Fermer le radar
                      Navigator.pop(context); // Fermer le bottom sheet
                      final codeSuivi = course.codeSuivi;
                      ref.read(demandeExpeditionProvider.notifier).reinitialiser();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(child: Text("Commande créée ! Code: $codeSuivi")),
                            ],
                          ),
                          backgroundColor: CouleursApp.succes,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      context.push('/suivi/${course.id}');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Fermer le radar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Hmm, quelque chose s'est mal passé : ${e.toString()} 🔧"),
                          backgroundColor: CouleursApp.erreur,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  "Confirmer la commande",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (etat.categorieService == "Remorque") {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: CouleursApp.primaire, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
