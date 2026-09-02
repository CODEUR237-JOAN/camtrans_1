import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/coeur/etat/suivi_provider.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/services/service_gps.dart';
import 'package:update_camtrans/fonctionnalites/client/widgets/carte_suivi_abstraite.dart';

class SuiviTransporteur extends ConsumerStatefulWidget {
  final String courseId;

  const SuiviTransporteur({super.key, required this.courseId});

  @override
  ConsumerState<SuiviTransporteur> createState() => _SuiviTransporteurState();
}

class _SuiviTransporteurState extends ConsumerState<SuiviTransporteur> {
  MapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(serviceGpsProvider).verifierPermissions().then((autorise) {
        if (!autorise && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Le GPS est nécessaire pour le suivi en temps réel."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.courseId.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF08111F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map_outlined, size: 80, color: Colors.white54),
              const SizedBox(height: 20),
              Text("Aucune course à suivre",
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      );
    }

    final etatSuivi = ref.watch(suiviProvider(widget.courseId));

    if (etatSuivi.chargement) {
      return const Scaffold(
        backgroundColor: Color(0xFF08111F),
        body: Center(child: CircularProgressIndicator(color: CouleursApp.primaire)),
      );
    }

    if (etatSuivi.course == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF08111F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF08111F),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: Text('Course introuvable.', style: TextStyle(color: Colors.white70))),
      );
    }

    final course = etatSuivi.course!;
    final transporteur = etatSuivi.transporteur;

    final LatLng depart = LatLng(course.latitudeDepart, course.longitudeDepart);
    final LatLng arrivee = LatLng(course.latitudeArrivee, course.longitudeArrivee);

    LatLng posTransporteur = depart;
    if (transporteur != null && transporteur.latitude != 0 && transporteur.longitude != 0) {
      posTransporteur = LatLng(transporteur.latitude, transporteur.longitude);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      body: Stack(
        children: [
          // 1. CARTE (Abstraction avec itinéraire et ajustement automatique)
          CarteSuiviAbstraite(
            depart: depart,
            arrivee: arrivee,
            transporteur: posTransporteur,
            route: etatSuivi.infoTrajet?.points,
            onMapCreated: (ctrl) => _mapController = ctrl,
            isRemorque: course.categorieService == 'Remorque',
          ),

          // 2. BOUTON RETOUR
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => context.go('/tableau-bord-transporteur'),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),

          // 3. BOUTON RECENTRER
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.42,
            child: FloatingActionButton.small(
              backgroundColor: const Color(0xFF0F172A),
              onPressed: () => _mapController?.move(posTransporteur, 14),
              child: const Icon(Icons.my_location_rounded, color: CouleursApp.primaire),
            ),
          ),

          // 4. PANNEAU BAS
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildPanneauBas(context, course),
          ),
        ],
      ),
    );
  }

  Widget _buildPanneauBas(BuildContext context, dynamic course) {
    final statut = course.statut as String;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poignée
            Center(
              child: Container(
                width: 40, height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
              ),
            ),

            // En-tête
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Course en cours", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                    Text(course.codeSuivi, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CouleursApp.succes.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CouleursApp.succes.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _libeleStatut(statut),
                    style: GoogleFonts.inter(color: CouleursApp.succes, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),

            const Divider(height: 28, color: Colors.white12),

            // Infos client
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: CouleursApp.primaire.withValues(alpha: 0.15),
                  child: const Icon(Icons.person_rounded, color: CouleursApp.primaire, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.nomClient.isNotEmpty ? course.nomClient : "Client",
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text("Client", style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                if (course.telephoneClient.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Appel de ${course.telephoneClient}...")),
                      );
                    },
                    icon: const Icon(Iconsax.call_copy, color: CouleursApp.succes, size: 22),
                    style: IconButton.styleFrom(
                      backgroundColor: CouleursApp.succes.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Adresses
            _buildInfoLigne(Icons.location_on, "Départ", course.adresseDepart, Colors.redAccent),
            const SizedBox(height: 10),
            _buildInfoLigne(Icons.flag_rounded, "Destination", course.adresseArrivee, Colors.greenAccent),

            const SizedBox(height: 16),

            // === DÉTAILS DU SERVICE CHOISI ===
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Détails de la mission",
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  if (course.categorieService.isNotEmpty)
                    _buildInfoLigne(Icons.category_rounded, "Service", course.categorieService, CouleursApp.primaire),
                  if (course.optionGamme.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoLigne(Icons.star_rounded, "Gamme", course.optionGamme, Colors.amberAccent),
                  ],
                  if (course.typeVehicule.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoLigne(Icons.local_shipping_rounded, "Véhicule requis", course.typeVehicule, Colors.blueAccent),
                  ],
                  if (course.typeMarchandise.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoLigne(Icons.inventory_2_rounded, "Marchandise", course.typeMarchandise, Colors.orangeAccent),
                  ],
                  if (course.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoLigne(Icons.notes_rounded, "Description", course.description, Colors.white70),
                  ],
                  if (course.detailsSpecifiques.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoLigne(Icons.info_outline_rounded, "Détails", course.detailsSpecifiques, Colors.white54),
                  ],
                  if (course.aideChargement) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: CouleursApp.succes, size: 16),
                        const SizedBox(width: 8),
                        Text("Aide au chargement incluse", style: GoogleFonts.inter(color: CouleursApp.succes, fontSize: 12)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Montant
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Montant à percevoir", style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                  Text(
                    "${(course.prixFinal > 0 ? course.prixFinal : course.prixEstime).toStringAsFixed(0)} FCFA",
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Bouton Terminer (sans code PIN)
            if (statut != StatutCourse.terminee && statut != StatutCourse.annulee)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _terminerCourse(context, course),
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: Text(
                    "Terminer la course",
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CouleursApp.succes,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),

            if (statut == StatutCourse.terminee)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CouleursApp.succes.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CouleursApp.succes.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: CouleursApp.succes),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Course terminée ! En attente du paiement client.",
                        style: GoogleFonts.inter(color: CouleursApp.succes, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoLigne(IconData icone, String label, String valeur, Color couleur) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, color: couleur, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600)),
              Text(valeur.isNotEmpty ? valeur : "—", style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  String _libeleStatut(String statut) {
    switch (statut) {
      case StatutCourse.propose: return "Proposé";
      case StatutCourse.attribue: return "Attribué";
      case StatutCourse.enRouteDepart: return "En route → Départ";
      case StatutCourse.arriveDepart: return "Arrivé au départ";
      case StatutCourse.charge: return "Chargé";
      case StatutCourse.enTransit: return "En transit";
      case StatutCourse.arriveDestination: return "Arrivé destination";
      case StatutCourse.terminee: return "Terminée ✅";
      case StatutCourse.annulee: return "Annulée ❌";
      default: return statut;
    }
  }

  void _terminerCourse(BuildContext context, dynamic course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Confirmer la fin de course", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Confirmez-vous que la livraison est terminée et la marchandise remise au client ?",
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Non, annuler", style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              HapticFeedback.heavyImpact();
              await ref.read(serviceFirestoreProvider).modifierDocument(
                collection: 'courses',
                id: course.id,
                donnees: {
                  'statut': StatutCourse.terminee,
                  'fondsDebloques': true,
                },
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Course terminée ! En attente du paiement client.", style: GoogleFonts.inter(color: Colors.white)),
                    backgroundColor: CouleursApp.succes,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CouleursApp.succes,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Oui, terminer", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
