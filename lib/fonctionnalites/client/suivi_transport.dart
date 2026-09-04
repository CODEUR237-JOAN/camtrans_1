import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../coeur/etat/demande_expedition_provider.dart';
import '../../coeur/etat/textes_app_provider.dart';
import '../../coeur/etat/utilisateur_provider.dart';
import '../../modeles/textes_app.dart';
import 'package:update_camtrans/coeur/etat/suivi_provider.dart';
import 'package:update_camtrans/services/service_gps.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'widgets/timeline_statut.dart';
import 'widgets/carte_suivi_abstraite.dart';
import 'widgets/bottom_sheet_paiement.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/recherche_radar.dart';
class SuiviTransport extends ConsumerStatefulWidget {
  final String courseId;
  final bool isFullScreen;

  const SuiviTransport({super.key, required this.courseId, this.isFullScreen = true});

  @override
  ConsumerState<SuiviTransport> createState() => _SuiviTransportState();
}

class _SuiviTransportState extends ConsumerState<SuiviTransport> {
  MapController? _mapController;

  @override
  void initState() {
    super.initState();
    // Vérifier les permissions GPS au chargement
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
    // Si aucun courseId fourni, afficher un état vide propre
    final textes = ref.watch(textesAppProvider).value ?? const TextesApp();
    if (widget.courseId.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF08111F),
        appBar: AppBar(
          title: const Text('Suivi', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF08111F),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_shipping_outlined, size: 80, color: Colors.white54),
             const SizedBox(height: 20),
            Text(textes.get('vide_course_client', "Aucune course active à suivre. Où allons-nous aujourd'hui ? 🚀"), style: const TextStyle(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    final String courseId = widget.courseId;
    final etatSuivi = ref.watch(suiviProvider(courseId));
    final roleAsync = ref.watch(userRoleProvider);
    final estClient = roleAsync.valueOrNull == 'client';

    // ✅ Paiement automatique : dès que la course passe à 'terminee', ouvrir le volet de paiement (client uniquement)
    ref.listen<EtatSuivi>(suiviProvider(courseId), (previous, next) {
      if (!estClient) return;
      final ancienStatut = previous?.course?.statut;
      final nouveauStatut = next.course?.statut;
      if (ancienStatut != StatutCourse.terminee && nouveauStatut == StatutCourse.terminee) {
        if (next.course?.paiementEffectue == false) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _confirmerFinCourse(context);
          });
        }
      }
    });

    if (etatSuivi.chargement) {
      return const Scaffold(
        backgroundColor: Color(0xFF08111F),
        body: Center(child: CircularProgressIndicator(color: CouleursApp.primaire)),
      );
    }

    if (etatSuivi.erreur != null || etatSuivi.course == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF08111F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF08111F),
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF08111F)),
        ),
        body: const Center(child: Text('Course introuvable ou inaccessible.')),
      );
    }

    final course = etatSuivi.course!;

    // ✅ PHASE 4: DISPATCH - Logique de Timeout côté Client (Zéro Coût Cloud Functions)
    if (estClient && course.statut == StatutCourse.propose && course.expirationProposition != null) {
      if (DateTime.now().isAfter(course.expirationProposition!)) {
        // Le délai est dépassé, on passe au transporteur suivant
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _passerAuTransporteurSuivant(course);
        });
      }
    }

    // Affichage du Radar continu tant qu'aucun transporteur n'a accepté
    if (course.statut == StatutCourse.recherche || course.statut == StatutCourse.propose) {
      return Scaffold(
        backgroundColor: const Color(0xFF08111F),
        body: Stack(
          children: [
            const RechercheRadar(), // Votre widget de Radar existant
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              child: _buildBackButton(context),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    "Recherche du meilleur transporteur...",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.statut == StatutCourse.propose 
                      ? "En attente de la réponse du candidat idéal..."
                      : "Analyse des transporteurs disponibles...",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => _confirmerAnnulation(context),
                    style: TextButton.styleFrom(foregroundColor: CouleursApp.erreur),
                    child: const Text("Annuler l'expédition"),
                  )
                ],
              ),
            )
          ],
        ),
      );
    }

    final transporteur = etatSuivi.transporteur;

    final LatLng depart = LatLng(course.latitudeDepart, course.longitudeDepart);
    final LatLng arrivee = LatLng(course.latitudeArrivee, course.longitudeArrivee);
    
    LatLng posTransporteur = depart;
    if (transporteur != null && transporteur.latitude != 0 && transporteur.longitude != 0) {
      posTransporteur = LatLng(transporteur.latitude, transporteur.longitude);
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. CARTE (Abstraction)
          CarteSuiviAbstraite(
            depart: depart,
            arrivee: arrivee,
            transporteur: posTransporteur,
            route: etatSuivi.infoTrajet?.points,
            onMapCreated: (ctrl) => _mapController = ctrl,
            isRemorque: course.categorieService == 'Remorque',
          ),

          // 2. BOUTON RETOUR
          if (widget.isFullScreen)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              child: _buildBackButton(context),
            ),

          // 3. BOUTON RECENTRER
          Positioned(
            right: 20,
            bottom: MediaQuery.of(context).size.height * 0.45,
            child: _buildLocationButton(posTransporteur),
          ),

          // 4. BOTTOM SHEET TIMELINE & INFOS
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomSheet(
              context, 
              course,
              transporteur, 
              etatSuivi.quartierTransporteur,
              etatSuivi.distanceRestante, 
              etatSuivi.tempsRestantSeconds
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF08111F), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4))]),
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }

  Widget _buildLocationButton(LatLng posTransporteur) {
    return GestureDetector(
      onTap: () {
        if (_mapController != null) {
          _mapController!.move(posTransporteur, 14.5);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF08111F), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4))]),
        child: const Icon(Iconsax.location_copy, color: CouleursApp.primaire),
      ),
    );
  }

  Widget _buildInfosTrajet(double distanceMetres, double tempsSecondes) {
    final distKm = (distanceMetres / 1000).toStringAsFixed(1);
    final min = (tempsSecondes / 60).ceil();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: CouleursApp.primaire.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CouleursApp.primaire.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              const Icon(Icons.route, color: CouleursApp.primaire, size: 20),
              const SizedBox(width: 8),
              Text("$distKm km", style: const TextStyle(fontWeight: FontWeight.bold, color: CouleursApp.primaire)),
            ],
          ),
          Container(width: 1, height: 24, color: CouleursApp.primaire.withValues(alpha: 0.3)),
          Row(
            children: [
              const Icon(Icons.timer, color: CouleursApp.succes, size: 20),
              const SizedBox(width: 8),
              Text("$min min", style: const TextStyle(fontWeight: FontWeight.bold, color: CouleursApp.succes)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransporteurInfo(BuildContext context, Transporteur transporteur, String? quartier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF08111F), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24, 
            backgroundColor: CouleursApp.primaire.withValues(alpha: 0.1), 
            backgroundImage: transporteur.photo.isNotEmpty ? NetworkImage(transporteur.photo) : null,
            child: transporteur.photo.isEmpty ? const Icon(Icons.person, color: CouleursApp.primaire) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${transporteur.prenom} ${transporteur.nom}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white), overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    const Icon(Iconsax.location_copy, size: 12, color: CouleursApp.primaire),
                    const SizedBox(width: 4),
                    Expanded(child: Text(quartier ?? "Localisation en cours...", style: const TextStyle(color: CouleursApp.primaire, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                Text(transporteur.typeVehicule.isEmpty ? "Véhicule utilitaire" : transporteur.typeVehicule, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  context.push("/chat", extra: {"transporteur": transporteur});
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(color: CouleursApp.secondaire.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Iconsax.message_copy, color: CouleursApp.secondaire, size: 20),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final Uri telUrl = Uri(scheme: 'tel', path: transporteur.telephone);
                  if (await canLaunchUrl(telUrl)) {
                    await launchUrl(telUrl);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: CouleursApp.primaire.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Iconsax.call_copy, color: CouleursApp.primaire, size: 20),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, Course course, Transporteur? transporteur, String? quartier, double distanceMetres, double tempsSecondes) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, -5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poignée du bottom sheet
          Center(
            child: Container(
              width: 40, height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          
          // Entête Course
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Course", style: TextStyle(color: Colors.black54, fontSize: 13)),
                  Text(course.codeSuivi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: CouleursApp.primaire.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text("En direct", style: TextStyle(color: CouleursApp.primaire, fontWeight: FontWeight.bold, fontSize: 12)),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(begin: 0.5, end: 1.0, duration: 1.seconds),
            ],
          ),
          const SizedBox(height: 12),

          // Adresses de la course
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(course.adresseDepart, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500))),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 9.0, top: 2, bottom: 2),
            child: Container(width: 2, height: 12, color: Colors.grey.shade300),
          ),
          Row(
            children: [
              const Icon(Icons.flag, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(course.adresseArrivee, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500))),
            ],
          ),

          const Divider(height: 24),

          // Infos Chauffeur
          if (transporteur != null) ...[
            _buildTransporteurInfo(context, transporteur, quartier),
            const SizedBox(height: 16),
          ],

          // ETA & Distance
          if (distanceMetres > 0) ...[
            _buildInfosTrajet(distanceMetres, tempsSecondes),
            const SizedBox(height: 24),
          ],

          // Timeline (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              child: TimelineStatut(statutActuel: course.statut),
            ),
          ),

          // Bouton "Terminer la course" ou "Je suis arrivé"
          if (course.statut == StatutCourse.arriveDestination || (course.statut == StatutCourse.enTransit && distanceMetres < 200)) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _confirmerFinCourse(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: course.statut == StatutCourse.arriveDestination ? CouleursApp.primaire : CouleursApp.succes,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  course.statut == StatutCourse.arriveDestination ? "Confirmer la livraison" : "Valider l'arrivée", 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],

          // Bouton d'annulation
          if (course.statut == StatutCourse.recherche || course.statut == StatutCourse.attribue || course.statut == StatutCourse.enRouteDepart) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _confirmerAnnulation(context),
                style: TextButton.styleFrom(foregroundColor: CouleursApp.erreur),
                child: const Text("Annuler l'expédition"),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmerAnnulation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Annuler l'expédition"),
        content: const Text("Êtes-vous sûr de vouloir annuler cette expédition ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Non, garder"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final courseId = widget.courseId;
              await ref.read(serviceFirestoreProvider).modifierDocument(
                collection: 'courses',
                id: courseId,
                donnees: {'statut': StatutCourse.annulee},
              );
              if (context.mounted) {
                context.go('/');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: CouleursApp.erreur, foregroundColor: Colors.white),
            child: const Text("Oui, annuler"),
          ),
        ],
      ),
    );
  }

  void _confirmerFinCourse(BuildContext context) {
    final course = ref
        .read(suiviProvider(widget.courseId))
        .course;

    if (course == null) return;

    // Si déjà payé → aller directement à l'évaluation
    if (course.paiementEffectue) {
      context.go('/evaluation/${course.id}');
      return;
    }

    final double montant =
        course.prixFinal > 0 ? course.prixFinal : course.prixEstime;

    // Afficher le bottom sheet de paiement (non-dismissable)
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BottomSheetPaiement(
        courseId: course.id,
        montant: montant > 0 ? montant : 5000,
        transporteurId: course.transporteurId,
        onPaiementReussi: () {
          Navigator.pop(ctx);
          if (context.mounted) {
            context.go('/evaluation/${course.id}');
          }
        },
      ),
    );
  }

  bool _enCoursDeRedirection = false;
  Future<void> _passerAuTransporteurSuivant(Course course) async {
    if (_enCoursDeRedirection) return;
    _enCoursDeRedirection = true;
    try {
      final List<dynamic> candidats = course.candidats;
      final int index = course.indexCandidatActuel;
      final int nextIndex = index + 1;

      final serviceFs = ref.read(serviceFirestoreProvider);

      if (nextIndex < candidats.length) {
        final prochainId = candidats[nextIndex] as String;
        await serviceFs.modifierDocument(
          collection: 'courses', 
          id: course.id,
          donnees: {
            'indexCandidatActuel': nextIndex,
            'transporteurId': prochainId,
            'expirationProposition': DateTime.now().add(const Duration(seconds: 30)).toIso8601String(),
          }
        );
        
        // Push notification for the next candidate
        await FirebaseFirestore.instance.collection('notifications_push').add({
           'titre': '🚨 NOUVELLE COURSE !',
           'message': 'Une course à proximité vous est proposée. Acceptez vite !',
           'cible': 'transporteur',
           'cibleId': prochainId,
           'status': 'pending',
           'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Plus aucun candidat : on passe au marché public
        await serviceFs.modifierDocument(
          collection: 'courses', 
          id: course.id,
          donnees: {
            'statut': StatutCourse.recherche,
            'transporteurId': '',
            'indexCandidatActuel': nextIndex,
          }
        );
      }
    } catch (e) {
      debugPrint("Erreur lors du passage au transporteur suivant: $e");
    } finally {
      // Petite pause avant de permettre un autre appel (debouncing)
      await Future.delayed(const Duration(seconds: 2));
      _enCoursDeRedirection = false;
    }
  }
}