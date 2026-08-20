import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/etat/transporteur_provider.dart';

class HistoriqueLivraisons extends ConsumerWidget {
  const HistoriqueLivraisons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(fluxMesCoursesProvider);

    return Scaffold(
      backgroundColor: CouleursApp.fond,
      appBar: AppBar(
        title: const Text("Historique des livraisons"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      body: Padding(
        padding: EdgeInsets.all(TaillesApp.margePage),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: CouleursApp.degradePrincipal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.history, color: Colors.white, size: 45),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Historique", style: TextStyle(color: Colors.white70)),
                        SizedBox(height: 6),
                        Text(
                          "Toutes vos livraisons réalisées sont enregistrées ici.",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: coursesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: CouleursApp.primaire)),
                error: (error, _) => Center(child: Text("Erreur : $error")),
                data: (courses) {
                  if (courses.isEmpty) {
                    return const Center(child: Text("Aucune livraison dans votre historique."));
                  }

                  return ListView.builder(
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.green.shade100,
                            child: const Icon(Icons.local_shipping, color: Colors.green),
                          ),
                          title: Text(
                            "${course.adresseDepart} → ${course.adresseArrivee}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(DateFormat('dd MMMM yyyy').format(course.dateCreation)),
                              Text(
                                course.statut.toUpperCase(),
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "${course.prixFinal > 0 ? course.prixFinal : course.prixEstime} F",
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Icon(Icons.arrow_forward_ios, size: 16)
                            ],
                          ),
                          onTap: () {
                            // En vrai on devrait ouvrir details_course.dart 
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Détails bientôt disponibles.")));
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}