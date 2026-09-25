import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';

import 'package:go_router/go_router.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import '../etat/suivi_course_etat.dart';

class PanneauDetailsBottomSheet extends StatelessWidget {
  final SuiviCourseEtat etat;
  final VoidCallback onBoutonAction;
  final bool isChauffeur;

  const PanneauDetailsBottomSheet({
    Key? key,
    required this.etat,
    required this.onBoutonAction,
    this.isChauffeur = false,
  }) : super(key: key);

  void _appeler(String numero) async {
    final Uri url = Uri.parse('tel:$numero');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (etat.course == null) return const SizedBox.shrink();
    
    final course = etat.course!;
    final titre = etat.phase == PhaseSuivi.approche
        ? (isChauffeur ? "En approche : ${etat.distanceRestanteMetres}m" : "Le chauffeur arrive (${etat.distanceRestanteMetres}m)")
        : (isChauffeur ? "Trajet vers la destination" : "En route vers la destination");

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.15, // Juste la poignée et le titre
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: CouleursApp.fondSombreSecondaire,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poignée de glissement
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Titre et ETA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          titre,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (etat.tempsRestantSecondes > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC1652F).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${(etat.tempsRestantSecondes / 60).ceil()} min",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFC1652F),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Informations sur le contact
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: CouleursApp.primaire.withValues(alpha: 0.2),
                        child: Icon(
                          isChauffeur ? Icons.person : Icons.local_shipping,
                          color: CouleursApp.primaire,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isChauffeur ? course.nomClient : course.nomTransporteur,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              isChauffeur ? "Client" : "${course.typeVehicule} - ${course.prixFinal} FCFA",
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          GoRouter.of(context).push('/chat', extra: {'courseId': course.id});
                        },
                        icon: const Icon(Icons.chat, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFC1652F), // Ocre charte
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _appeler(
                            isChauffeur ? course.telephoneClient : course.telephoneTransporteur),
                        icon: const Icon(Icons.phone, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF145C43), // Vert charte
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 32),

                  // Bouton d'action principal (Commencer/Terminer la course)
                  if (isChauffeur && etat.phase == PhaseSuivi.approche)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onBoutonAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC1652F), // Ocre pour attirer l'attention
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "Commencer la course",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else if (isChauffeur && etat.phase == PhaseSuivi.trajet)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onBoutonAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF145C43), // Vert charte
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "Terminer la course",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else if (!isChauffeur && etat.course?.statut == StatutCourse.arriveDestination)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final c = etat.course!;
                          final double montant = c.prixFinal > 0 ? c.prixFinal : c.prixEstime;
                          GoRouter.of(context).push('/paiement', extra: {
                            'courseId': c.id,
                            'montant': montant,
                            'transporteurId': c.transporteurId,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CouleursApp.succes,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "Procéder au paiement",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                  // Espacement pour scroller confortablement
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  String get distance {
    if (etat.distanceRestanteMetres > 1000) {
      return "${(etat.distanceRestanteMetres / 1000).toStringAsFixed(1)} km";
    }
    return "${etat.distanceRestanteMetres} m";
  }
}
