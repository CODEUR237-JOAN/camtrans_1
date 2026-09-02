import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:update_camtrans/coeur/etat/transporteur_provider.dart';
import 'package:update_camtrans/services/service_gps.dart';
import 'package:update_camtrans/fonctionnalites/transporteur/suivi_transporteur.dart';

class NavigationTransporteur extends ConsumerStatefulWidget {
  const NavigationTransporteur({super.key});

  @override
  ConsumerState<NavigationTransporteur> createState() => _NavigationTransporteurState();
}

class _NavigationTransporteurState extends ConsumerState<NavigationTransporteur> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(serviceGpsProvider).verifierPermissions().then((autorise) {
        if (!autorise && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Le GPS est requis pour guider votre trajet."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCourse = ref.watch(activeCourseProvider);

    if (activeCourse == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF08111F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map_outlined, size: 80, color: Colors.white54),
              const SizedBox(height: 20),
              const Text("Aucune course active", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              const SizedBox(height: 10),
              const Text("Acceptez une course sur le marché pour commencer.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    // Le transporteur est redirigé vers SA vue de suivi complète
    return SuiviTransporteur(courseId: activeCourse.id);
  }
}
