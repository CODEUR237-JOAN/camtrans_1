import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';
import 'package:update_camtrans/modeles/entretien.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_firestore.dart';

// =====================================================================
// Écran : Entretien du véhicule (transporteur)
//
// Branché en temps réel sur la collection Firestore "entretiens".
// Le transporteur peut consulter, ajouter et supprimer ses entretiens.
// (Auparavant 100 % statique avec des données codées en dur.)
// =====================================================================
class EcranEntretien extends ConsumerStatefulWidget {
  const EcranEntretien({super.key});

  @override
  ConsumerState<EcranEntretien> createState() => _EntretienState();
}

class _EntretienState extends ConsumerState<EcranEntretien> {
  Color get _fond => Theme.of(context).scaffoldBackgroundColor;
  Color get _carte => Theme.of(context).colorScheme.surface;

  // ------- Mapping catégorie -> icône / couleur -------
  static const Map<String, IconData> _icones = {
    'vidange': Icons.oil_barrel,
    'pneus': Icons.tire_repair,
    'visite': Icons.car_repair,
    'freinage': Icons.settings_suggest,
    'autre': Icons.build,
  };
  static const Map<String, Color> _couleurs = {
    'vidange': Colors.orange,
    'pneus': Colors.blue,
    'visite': Colors.green,
    'freinage': Colors.red,
    'autre': CouleursApp.primaire,
  };

  IconData _iconePour(String t) => _icones[t] ?? Icons.build;
  Color _couleurPour(String t) => _couleurs[t] ?? CouleursApp.primaire;

  String? get _uid =>
      ref.read(serviceAuthentificationProvider).utilisateur?.uid;

  // -----------------------------------------------------------------
  // Ajout / édition via une feuille de formulaire
  // -----------------------------------------------------------------
  Future<void> _ouvrirFormulaire({Entretien? existant}) async {
    final uid = _uid;
    if (uid == null) return;

    final resultat = await showModalBottomSheet<Entretien>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FormulaireEntretien(
        transporteurId: uid,
        existant: existant,
      ),
    );

    if (resultat == null || !mounted) return;

    try {
      await ref.read(serviceFirestoreProvider).ajouterDocument(
            collection: 'entretiens',
            id: resultat.id,
            donnees: resultat.toMap(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(existant == null
              ? 'Entretien ajouté'
              : 'Entretien mis à jour'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de l\'enregistrement : $e'),
          backgroundColor: CouleursApp.erreur,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _supprimer(Entretien e) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _carte,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Supprimer cet entretien ?',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 17)),
        content: Text(
          '« ${e.titre} » sera définitivement supprimé.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: CouleursApp.erreur,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ref
          .read(serviceFirestoreProvider)
          .supprimerDocument(collection: 'entretiens', id: e.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Entretien supprimé'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Suppression impossible : $err'),
          backgroundColor: CouleursApp.erreur,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // -----------------------------------------------------------------
  // BUILD
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    final service = ref.read(serviceFirestoreProvider);

    return Scaffold(
      backgroundColor: _fond,
      appBar: AppBar(
        backgroundColor: _fond,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        title: Text('Entretien du véhicule',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CouleursApp.primaire,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () => _ouvrirFormulaire(),
      ),
      body: uid == null
          ? Center(
              child: Text('Vous devez être connecté.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.fluxCollectionCondition(
                collection: 'entretiens',
                champ: 'transporteurId',
                valeur: uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LoaderPremium());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Impossible de charger les entretiens.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                      ),
                    ),
                  );
                }

                final entretiens = (snapshot.data?.docs ?? [])
                    .map((d) => Entretien.fromMap(d.data()))
                    .toList()
                  ..sort((a, b) => b.dateDernier.compareTo(a.dateDernier));

                if (entretiens.isEmpty) {
                  return _etatVide();
                }

                final nbBientot = entretiens.where((e) => e.bientotDu).length;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _bandeauStats(entretiens.length, nbBientot),
                    const SizedBox(height: 24),
                    Text('Historique',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    ...entretiens.map(_carteEntretien),
                  ],
                );
              },
            ),
    );
  }

  // -------- Widgets --------

  Widget _bandeauStats(int total, int bientot) {
    return Row(
      children: [
        Expanded(child: _stat('Entretiens', '$total', Icons.build, CouleursApp.primaire)),
        const SizedBox(width: 14),
        Expanded(
            child: _stat('À prévoir', '$bientot', Icons.schedule,
                bientot > 0 ? Colors.orange : Colors.green)),
      ],
    );
  }

  Widget _stat(String titre, String valeur, IconData icone, Color couleur) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _carte,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: couleur, size: 24),
          const SizedBox(height: 10),
          Text(valeur,
              style: TextStyle(
                  color: couleur,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          Text(titre,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _carteEntretien(Entretien e) {
    final couleur = _couleurPour(e.type);
    final df = DateFormat('dd MMM yyyy');
    return Dismissible(
      key: Key(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: CouleursApp.erreur,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        await _supprimer(e);
        return false; // la liste se met à jour via le stream Firestore
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _carte,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: couleur.withValues(alpha: 0.15),
            child: Icon(_iconePour(e.type), color: couleur),
          ),
          title: Text(e.titre,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text('Dernier : ${df.format(e.dateDernier)}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12.5)),
              if (e.dateProchain != null)
                Row(
                  children: [
                    Text('Prochain : ${df.format(e.dateProchain!)}',
                        style: TextStyle(
                            color: e.bientotDu ? Colors.orange : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 12.5,
                            fontWeight:
                                e.bientotDu ? FontWeight.bold : FontWeight.normal)),
                    if (e.bientotDu) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.orange, size: 14),
                    ],
                  ],
                ),
              if (e.note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(e.note,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined, color: CouleursApp.primaire),
            onPressed: () => _ouvrirFormulaire(existant: e),
          ),
          onTap: () => _ouvrirFormulaire(existant: e),
        ),
      ),
    );
  }

  Widget _etatVide() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: CouleursApp.primaire.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.build_circle_outlined,
                  color: CouleursApp.primaire, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Aucun entretien enregistré',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Suivez les entretiens de votre véhicule pour ne rien oublier. '
              'Appuyez sur « Ajouter » pour créer le premier.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Formulaire d'ajout / édition d'un entretien (bottom sheet)
// Retourne un objet Entretien via Navigator.pop, ou null si annulé.
// =====================================================================
class _FormulaireEntretien extends StatefulWidget {
  final String transporteurId;
  final Entretien? existant;

  const _FormulaireEntretien({
    required this.transporteurId,
    this.existant,
  });

  @override
  State<_FormulaireEntretien> createState() => _FormulaireEntretienState();
}

class _FormulaireEntretienState extends State<_FormulaireEntretien> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titre;
  late final TextEditingController _note;
  late String _type;
  late DateTime _dateDernier;
  DateTime? _dateProchain;

  static const Map<String, String> _types = {
    'vidange': 'Vidange',
    'pneus': 'Pneus',
    'visite': 'Visite technique',
    'freinage': 'Freinage',
    'autre': 'Autre',
  };

  @override
  void initState() {
    super.initState();
    final e = widget.existant;
    _titre = TextEditingController(text: e?.titre ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _type = e?.type ?? 'vidange';
    _dateDernier = e?.dateDernier ?? DateTime.now();
    _dateProchain = e?.dateProchain;
  }

  @override
  void dispose() {
    _titre.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _choisirDate({required bool dernier}) async {
    final initiale =
        dernier ? _dateDernier : (_dateProchain ?? DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: initiale,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: CouleursApp.primaire),
        ),
        child: child!,
      ),
    );
    if (date == null) return;
    setState(() {
      if (dernier) {
        _dateDernier = date;
      } else {
        _dateProchain = date;
      }
    });
  }

  void _enregistrer() {
    if (!_formKey.currentState!.validate()) return;
    final e = widget.existant;
    final entretien = Entretien(
      id: e?.id ?? 'ENT-${DateTime.now().millisecondsSinceEpoch}',
      transporteurId: widget.transporteurId,
      titre: _titre.text.trim(),
      type: _type,
      dateDernier: _dateDernier,
      dateProchain: _dateProchain,
      note: _note.text.trim(),
      dateCreation: e?.dateCreation ?? DateTime.now(),
    );
    Navigator.pop(context, entretien);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.existant == null
                    ? 'Nouvel entretien'
                    : 'Modifier l\'entretien',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),

              // Intitulé
              TextFormField(
                controller: _titre,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: _deco('Intitulé', 'Ex : Vidange moteur'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Veuillez saisir un intitulé'
                    : null,
              ),
              const SizedBox(height: 16),

              // Catégorie
              Text('Catégorie',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types.entries.map((entry) {
                  final selectionne = _type == entry.key;
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: selectionne,
                    onSelected: (_) => setState(() => _type = entry.key),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedColor: CouleursApp.primaire,
                    labelStyle: TextStyle(
                        color: selectionne ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: _champDate(
                      libelle: 'Dernier entretien',
                      valeur: df.format(_dateDernier),
                      onTap: () => _choisirDate(dernier: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _champDate(
                      libelle: 'Prochain (option.)',
                      valeur:
                          _dateProchain == null ? '—' : df.format(_dateProchain!),
                      onTap: () => _choisirDate(dernier: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _note,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                maxLines: 2,
                decoration: _deco('Note (option.)',
                    'Kilométrage, garage, pièces changées...'),
              ),
              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CouleursApp.primaire,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _enregistrer,
                  child: const Text('Enregistrer',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CouleursApp.primaire),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CouleursApp.erreur),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CouleursApp.erreur),
      ),
    );
  }

  Widget _champDate({
    required String libelle,
    required String valeur,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(libelle,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: CouleursApp.primaire, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(valeur,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
