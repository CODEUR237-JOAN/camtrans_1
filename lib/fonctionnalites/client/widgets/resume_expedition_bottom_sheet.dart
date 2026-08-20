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
import 'carte_estimation.dart';
import 'recherche_radar.dart';
import 'carte_estimation_remorque.dart';

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
        color: etat.categorieService == "Remorque" ? const Color(0xFF0F172A).withValues(alpha: 0.85) : Colors.white,
        borderRadius: etat.categorieService == "Remorque" ? BorderRadius.circular(24.0) : const BorderRadius.vertical(top: Radius.circular(24.0)),
        border: etat.categorieService == "Remorque" ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
        boxShadow: etat.categorieService == "Remorque"
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: -5)]
            : null,
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
                color: Colors.grey.shade300,
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
                            color: etat.categorieService == "Remorque" ? Colors.white : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: etat.categorieService == "Remorque" ? Colors.white : Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  _buildInfoRow(context, Iconsax.location_copy, "Trajet", "${etat.depart} ➔ ${etat.destination}"),
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
                      child: CircularProgressIndicator(color: CouleursApp.primaire),
                    ))
                  else if (etatEstimation.erreur != null)
                    Text("Erreur: ${etatEstimation.erreur}", style: const TextStyle(color: Colors.red))
                  else if (etatEstimation.resultat != null)
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
                        colors: [Color(0xFF12B76A), Color(0xFF0E9456)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                boxShadow: [
                  BoxShadow(
                    color: etat.categorieService == "Remorque"
                        ? const Color(0xFF12B76A).withValues(alpha: 0.35)
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
                      const SnackBar(content: Text("Erreur: Vous n'êtes pas connecté.")),
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

                  if (etat.chauffeurPropose == null) {
                    final vehiculeRequis = etatEstimation.resultat?.vehiculeRecommande ?? etat.categorieVehicule;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Aucun transporteur disponible ($vehiculeRequis) dans votre zone."),
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

                    final course = Course(
                      id: courseId,
                      clientId: user.uid,
                      transporteurId: etat.chauffeurPropose?.id ?? '',
                      nomClient: user.displayName ?? "Client Anonyme",
                      nomTransporteur: etat.chauffeurPropose != null
                          ? "${etat.chauffeurPropose!.prenom} ${etat.chauffeurPropose!.nom}"
                          : '',
                      telephoneClient: '',
                      telephoneTransporteur: etat.chauffeurPropose?.telephone ?? '',
                      adresseDepart: etat.depart,
                      adresseArrivee: etat.destination,
                      latitudeDepart: latDepart,
                      longitudeDepart: lngDepart,
                      latitudeArrivee: latArrivee,
                      longitudeArrivee: lngArrivee,
                      distanceKm: distanceKm,
                      volumeM3: etatEstimation.resultat?.volumeM3 ?? 0.0,
                      poidsKg: 0.0,
                      typeVehicule: etatEstimation.resultat?.vehiculeRecommande ?? etat.categorieVehicule,
                      typeMarchandise: etat.typeMarchandise.isNotEmpty ? etat.typeMarchandise : etat.categorieService,
                      prixEstime: etatEstimation.resultat?.coutTotal ?? 0.0,
                      prixFinal: 0.0,
                      modePaiement: '',
                      paiementEffectue: false,
                      statut: etat.chauffeurPropose != null ? StatutCourse.attribue : StatutCourse.recherche,
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
                    );

                    await ref.read(serviceFirestoreProvider).ajouterDocument(
                      collection: 'courses',
                      id: course.id,
                      donnees: course.toMap(),
                    );

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
                          content: Text("Erreur : ${e.toString()}"),
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
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: label == "Détails" || label == "Service" || label == "Trajet" || label == "Véhicule" || label == "Chauffeur" || label == "Date de la demande" 
                    ? (ref.read(demandeExpeditionProvider).categorieService == "Remorque" ? Colors.white : Colors.black)
                    : null,
              )),
            ],
          ),
        ),
      ],
    );
  }
}
