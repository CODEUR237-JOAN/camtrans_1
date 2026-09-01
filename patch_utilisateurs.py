import re

with open('lib/fonctionnalites/admin/pages/page_utilisateurs.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update TabController length
content = content.replace('length: 2', 'length: 3')

# 2. Add Tab
content = content.replace('Tab(text: "Transporteurs"),', 'Tab(text: "Transporteurs"),\n                    Tab(text: "Validations Confort"),')

# 3. Add TabView child
content = content.replace('_buildListeTransporteurs(ref),', '_buildListeTransporteurs(ref),\n                    _buildDemandesConfort(ref),')

# 4. TabBar width (to fit 3 tabs)
content = content.replace('width: 300,', 'width: 450,')

# 5. Build method for Demandes Confort
demandes_confort = '''  Widget _buildDemandesConfort(WidgetRef ref) {
    final transporteursAsync = ref.watch(adminTransporteursProvider);

    return transporteursAsync.when(
      loading: () => const EtatChargement(),
      error: (err, _) => EtatErreur(erreur: err.toString(), onRetry: () => ref.refresh(adminTransporteursProvider)),
      data: (tousTransporteurs) {
        final demandes = tousTransporteurs.where((t) {
          final isMatchSearch = ("${t.prenom} ${t.nom}".toLowerCase().contains(_searchQuery) || t.email.toLowerCase().contains(_searchQuery));
          return t.gamme == "Confort" && !t.gammeValidee && isMatchSearch;
        }).toList();

        if (demandes.isEmpty) {
          return Center(child: Text("Aucune demande de validation Confort en attente.", style: GoogleFonts.inter(color: Colors.white54)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          itemCount: demandes.length,
          itemBuilder: (context, index) {
            final t = demandes[index];
            final initiale = (t.nom.isNotEmpty ? t.nom[0] : (t.prenom.isNotEmpty ? t.prenom[0] : '?')).toUpperCase();
            return _GlassListItem(
              titre: "${t.prenom} ${t.nom}".trim().isNotEmpty ? "${t.prenom} ${t.nom}".trim() : t.email,
              sousTitre: "Immatriculation: ${t.immatriculation} | Véhicule: ${t.typeVehicule}",
              initiale: initiale,
              couleurInitiale: Colors.amber,
              estActif: t.actif,
              estEnLigne: t.estEnLigne,
              onTap: () {
                _afficherDetailsDemandeConfort(context, ref, t);
              },
            );
          },
        );
      },
    );
  }

  void _afficherDetailsDemandeConfort(BuildContext context, WidgetRef ref, Transporteur t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: Text("Validation Confort : ${t.prenom} ${t.nom}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Véhicule: ${t.typeVehicule}", style: const TextStyle(color: Colors.white70)),
              Text("Immatriculation: ${t.immatriculation}", style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 15),
              const Text("Photos de vérification :", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (t.photosInspectionVehicule.isEmpty)
                const Text("Aucune photo fournie.", style: TextStyle(color: Colors.redAccent))
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: t.photosInspectionVehicule.map((url) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(url, width: 120, height: 120, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 120, height: 120, color: Colors.grey[800],
                          child: const Icon(Icons.broken_image, color: Colors.white54),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejeterDemandeConfort(context, ref, t);
            },
            child: const Text("Rejeter (Gamme Éco)", style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context);
              _validerDemandeConfort(context, ref, t);
            },
            child: const Text("Valider Confort", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _validerDemandeConfort(BuildContext context, WidgetRef ref, Transporteur t) async {
    try {
      final db = ref.read(serviceFirestoreProvider);
      await db.mettreAJourDocument(
        collection: 'transporteurs',
        id: t.id,
        donnees: {'gammeValidee': true},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Statut Confort validé avec succès."), backgroundColor: Colors.green));
      }
    } catch(e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _rejeterDemandeConfort(BuildContext context, WidgetRef ref, Transporteur t) async {
    try {
      final db = ref.read(serviceFirestoreProvider);
      await db.mettreAJourDocument(
        collection: 'transporteurs',
        id: t.id,
        donnees: {'gamme': 'Éco', 'gammeValidee': true},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Demande rejetée, le transporteur passe en Éco."), backgroundColor: Colors.orange));
      }
    } catch(e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red));
      }
    }
  }

}'''

# find the last closing brace and replace it
last_brace_index = content.rfind('}')
if last_brace_index != -1:
    content = content[:last_brace_index] + demandes_confort + '\n'

with open('lib/fonctionnalites/admin/pages/page_utilisateurs.dart', 'w', encoding='utf-8') as f:
    f.write(content)
