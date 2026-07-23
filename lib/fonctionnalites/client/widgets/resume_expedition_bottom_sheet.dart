import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../coeur/etat/demande_expedition_provider.dart';
import '../../../coeur/etat/estimation_provider.dart';
import '../../../coeur/constantes/couleurs.dart';
import '../../../services/service_firestore.dart';
import '../../../services/service_authentification.dart';
import '../../../services/service_gps.dart';
import '../../../modeles/course.dart';
import 'package:uuid/uuid.dart';
import 'carte_estimation.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final etatDemande = ref.read(demandeExpeditionProvider);
      ref.read(estimationProvider.notifier).lancerEstimation(
        depart: etatDemande.depart,
        arrivee: etatDemande.destination,
        typeMarchandise: etatDemande.typeMarchandise,
        description: etatDemande.description,
        categorieVehicule: etatDemande.categorieVehicule,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(demandeExpeditionProvider);
    final etatEstimation = ref.watch(estimationProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  _buildInfoRow(context, Iconsax.location_copy, "Trajet", "${etat.depart} ➔ ${etat.destination}"),
                  const SizedBox(height: 16),
                  _buildInfoRow(context, Iconsax.box_copy, "Marchandise", etat.typeMarchandise),
                  const SizedBox(height: 16),
                  _buildInfoRow(context, Iconsax.truck_fast_copy, "Véhicule", etat.categorieVehicule),
                  const SizedBox(height: 16),
                  if (etat.dateTransport != null && etat.heureTransport != null)
                    _buildInfoRow(
                      context,
                      Iconsax.calendar_1_copy,
                      "Planification",
                      "${DateFormat('dd/MM/yyyy').format(etat.dateTransport!)} à ${etat.heureTransport!.format(context)}",
                    ),
                  if (etat.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow(context, Iconsax.textalign_left_copy, "Description", etat.description),
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
                              child: Image.file(
                                File(etat.photos[index].path),
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
                    CarteEstimationIntelligente(resultat: etatEstimation.resultat!),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () async {
                final user = ref.read(serviceAuthentificationProvider).utilisateur;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Erreur: Vous n'êtes pas connecté.")),
                  );
                  return;
                }

                // Afficher le chargement
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  final String courseId = 'course_${const Uuid().v4()}';
                  
                  // Récupération des URL des photos (ici simulé car pas de storage pour l'instant)
                  final List<String> photosUrl = [];
                  
                  // Géocodage des adresses et calcul de distance
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
                    transporteurId: '',
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
                    typeVehicule: etatEstimation.resultat?.vehiculeRecommande ?? etat.categorieVehicule,
                    typeMarchandise: etat.typeMarchandise,
                    prixEstime: etatEstimation.resultat?.coutTotal ?? 0.0,
                    prixFinal: 0.0,
                    modePaiement: '',
                    paiementEffectue: false,
                    statut: 'en_attente',
                    description: etat.description,
                    photos: photosUrl,
                    dateCreation: DateTime.now(),
                    dateDebut: etat.dateTransport,
                    fragile: false,
                    aideChargement: false,
                    aideDechargement: false,
                    codeSuivi: 'TRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                    noteClient: 0.0,
                    noteTransporteur: 0.0,
                    commentaireClient: '',
                    commentaireTransporteur: '',
                    scoreIA: 0.0,
                    vehiculeRecommandeIA: etatEstimation.resultat?.vehiculeRecommande ?? '',
                    volumeEstimeIA: etatEstimation.resultat?.volumeM3 ?? 0.0,
                    conseilIA: '',
                  );

                  await ref.read(serviceFirestoreProvider).ajouterDocument(
                    collection: 'courses',
                    id: course.id,
                    donnees: course.toMap(),
                  );

                  if (context.mounted) {
                    Navigator.pop(context); // Fermer le loader
                    Navigator.pop(context); // Fermer le bottom sheet
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Expédition créée avec succès !")),
                    );
                    ref.read(demandeExpeditionProvider.notifier).reinitialiser();
                    Navigator.pop(context); // Retourner au dashboard client
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Fermer le loader
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Erreur: ${e.toString()}")),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CouleursApp.primaire,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Confirmer l'expédition", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
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
              Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
