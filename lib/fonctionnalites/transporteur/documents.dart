import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/etat/transporteur_provider.dart';
import 'package:update_camtrans/services/service_stockage.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

class Documents extends ConsumerStatefulWidget {
  const Documents({super.key});

  @override
  ConsumerState<Documents> createState() => _DocumentsState();
}

class _DocumentsState extends ConsumerState<Documents> {
  bool _chargement = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _uploaderDocument(String documentId, String label, String fieldName, String transporteurId) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() => _chargement = true);
      try {
        final storage = ref.read(serviceStockageProvider);
        final url = await storage.uploaderFichier(
          fichier: image,
          dossier: 'documents_transporteurs',
          nomFichier: '${transporteurId}_$fieldName',
        );

        if (url != null) {
          await ref.read(serviceFirestoreProvider).modifierDocument(
            collection: 'transporteurs',
            id: transporteurId,
            donnees: {fieldName: url},
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$label importé avec succès !"), backgroundColor: Colors.green),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur lors de l'upload: $e"), backgroundColor: Colors.red),
          );
        }
      }
      setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transporteurId = ref.watch(currentTransporteurIdProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      appBar: AppBar(
        title: const Text("Mes documents"),
      ),
      body: StreamBuilder(
        stream: ref.watch(serviceFirestoreProvider).fluxDocument(collection: 'transporteurs', id: transporteurId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_chargement) {
            return Center(child: LoaderPremium());
          }
          
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Erreur de chargement des documents."));
          }
          
          final transporteur = Transporteur.fromMap(snapshot.data!.data() as Map<String, dynamic>);
          
          // Helper local
          Widget buildLigneDocument({
            required String label,
            required IconData icone,
            required String currentUrl,
            required String fieldName,
          }) {
            final estImporte = currentUrl.isNotEmpty;
            final couleur = estImporte ? Colors.green : Colors.red;
            
            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: couleur.withValues(alpha: .15),
                  child: Icon(icone, color: couleur),
                ),
                title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: couleur.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          estImporte ? "Importé" : "À importer",
                          style: TextStyle(color: couleur, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: _chargement ? const SizedBox(width: 20, height: 20, child: LoaderPremium()) : IconButton(
                  icon: Icon(estImporte ? Icons.edit : Icons.upload),
                  color: CouleursApp.primaire,
                  onPressed: () => _uploaderDocument(label, label, fieldName, transporteurId),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(TaillesApp.margePage),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: CouleursApp.degradePrincipal,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Documents du transporteur",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Uploadez des photos claires de vos documents afin d'être vérifié par l'administration.",
                        style: TextStyle(color: Colors.white, fontSize: 17),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Text("Liste des documents", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

                const SizedBox(height: 15),

                buildLigneDocument(
                  label: "Permis de conduire",
                  icone: Icons.drive_eta,
                  currentUrl: transporteur.photoPermis,
                  fieldName: "photoPermis",
                ),
                buildLigneDocument(
                  label: "Carte Grise",
                  icone: Icons.directions_car,
                  currentUrl: transporteur.photoCarteGrise,
                  fieldName: "photoCarteGrise",
                ),
                buildLigneDocument(
                  label: "Assurance",
                  icone: Icons.health_and_safety,
                  currentUrl: transporteur.photoAssurance,
                  fieldName: "photoAssurance",
                ),
                buildLigneDocument(
                  label: "Photo du Véhicule",
                  icone: Icons.local_shipping,
                  currentUrl: transporteur.photoVehicule,
                  fieldName: "photoVehicule",
                ),
                
                const SizedBox(height: 25),

                Card(
                  color: CouleursApp.primaire.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: const ListTile(
                    leading: Icon(Icons.info, color: Colors.blue),
                    title: Text("Conseil"),
                    subtitle: Text("Une fois tous les documents importés, l'équipe d'administration validera votre dossier."),
                  ),
                ),

                const SizedBox(height: 90),
              ],
            ),
          );
        }
      ),
    );
  }
}