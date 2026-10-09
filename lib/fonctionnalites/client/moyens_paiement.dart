import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/widgets/loader_page.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/l10n/app_localizations.dart';

// =====================================================================
// ÉCRAN : Moyens de paiement (client)
//
// Permet au client d'enregistrer ses numéros Mobile Money (Orange / MTN)
// pour un paiement plus rapide. Stockés dans un champ tableau
// `moyensPaiement` du document clients/{uid}. Opérationnel : ajout /
// suppression en temps réel, état vide et loader.
// =====================================================================
class MoyensPaiement extends ConsumerWidget {
  const MoyensPaiement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.read(serviceAuthentificationProvider).utilisateur?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF08111F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Moyens de paiement',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: CouleursApp.primaire,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Ajouter',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              onPressed: () => _ouvrirAjout(context, uid),
            ),
      body: uid == null
          ? const Center(
              child: Text('Vous devez être connecté.',
                  style: TextStyle(color: Colors.white70)),
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('clients')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoaderPage();
                }
                final data = snapshot.data?.data();
                final liste = (data?['moyensPaiement'] as List?) ?? [];
                if (liste.isEmpty) return const _EtatVide();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: liste.length,
                  itemBuilder: (context, index) {
                    final m = Map<String, dynamic>.from(liste[index] as Map);
                    return _CarteMoyen(
                      moyen: m,
                      onSupprimer: () => _supprimer(context, uid, m),
                    );
                  },
                );
              },
            ),
    );
  }

  // ------- Opérations Firestore -------
  Future<void> _ajouter(
      BuildContext context, String uid, Map<String, dynamic> moyen) async {
    try {
      await FirebaseFirestore.instance.collection('clients').doc(uid).set(
        {
          'moyensPaiement': FieldValue.arrayUnion([moyen])
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      if (context.mounted) {
        _toast(context, 'Ajout impossible : $e', erreur: true);
      }
    }
  }

  Future<void> _supprimer(
      BuildContext context, String uid, Map<String, dynamic> moyen) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF10192A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Supprimer ce moyen de paiement ?',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        content: Text('${moyen['operateur']} · ${moyen['numero']}',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: Colors.white54)),
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
    if (confirm != true) return;
    try {
      await FirebaseFirestore.instance.collection('clients').doc(uid).set(
        {
          'moyensPaiement': FieldValue.arrayRemove([moyen])
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      if (context.mounted) {
        _toast(context, 'Suppression impossible : $e', erreur: true);
      }
    }
  }

  void _ouvrirAjout(BuildContext context, String uid) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0C1524),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FeuilleAjout(
        onValider: (moyen) {
          Navigator.pop(context);
          _ajouter(context, uid, moyen);
        },
      ),
    );
  }

  void _toast(BuildContext context, String msg, {bool erreur = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: erreur ? CouleursApp.erreur : CouleursApp.succes,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ---------------------------------------------------------------------
class _CarteMoyen extends StatelessWidget {
  final Map<String, dynamic> moyen;
  final VoidCallback onSupprimer;
  const _CarteMoyen({required this.moyen, required this.onSupprimer});

  @override
  Widget build(BuildContext context) {
    final operateur = (moyen['operateur'] ?? '').toString();
    final estOrange = operateur.toLowerCase().contains('orange');
    final couleur =
        estOrange ? const Color(0xFFFF7900) : const Color(0xFFFFCC00);
    final numero = (moyen['numero'] ?? '').toString();
    final nom = (moyen['nom'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF10192A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: couleur.withValues(alpha: 0.18),
          child: Icon(Icons.smartphone, color: couleur),
        ),
        title: Text(numero,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
          nom.isNotEmpty ? '$operateur · $nom' : operateur,
          style: const TextStyle(color: Colors.white54, fontSize: 12.5),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: CouleursApp.erreur),
          onPressed: onSupprimer,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
class _EtatVide extends StatelessWidget {
  const _EtatVide();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: CouleursApp.primaire.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet_outlined,
                  color: CouleursApp.primaire, size: 46),
            ),
            const SizedBox(height: 18),
            const Text('Aucun moyen de paiement',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
              'Enregistrez vos numéros Mobile Money pour payer plus vite lors de vos courses.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
class _FeuilleAjout extends StatefulWidget {
  final void Function(Map<String, dynamic> moyen) onValider;
  const _FeuilleAjout({required this.onValider});

  @override
  State<_FeuilleAjout> createState() => _FeuilleAjoutState();
}

class _FeuilleAjoutState extends State<_FeuilleAjout> {
  final _formKey = GlobalKey<FormState>();
  final _numero = TextEditingController();
  final _nom = TextEditingController();
  String _operateur = 'Orange Money';

  @override
  void dispose() {
    _numero.dispose();
    _nom.dispose();
    super.dispose();
  }

  void _valider() {
    if (!_formKey.currentState!.validate()) return;
    widget.onValider({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'operateur': _operateur,
      'numero': _numero.text.trim(),
      'nom': _nom.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Nouveau moyen de paiement',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            const Text('Opérateur',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Orange Money', 'MTN Mobile Money'].map((o) {
                final sel = _operateur == o;
                return ChoiceChip(
                  label: Text(o),
                  selected: sel,
                  onSelected: (_) => setState(() => _operateur = o),
                  backgroundColor: const Color(0xFF10192A),
                  selectedColor: CouleursApp.primaire,
                  labelStyle: TextStyle(
                      color: sel ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white12),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numero,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: _deco(AppLocalizations.of(context)!.phoneNumber, Icons.phone_outlined),
              validator: (v) {
                final t = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                if (t.length < 9) return 'Numéro invalide';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nom,
              style: const TextStyle(color: Colors.white),
              decoration: _deco('Libellé (optionnel)', Icons.label_outline),
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
                onPressed: _valider,
                child: const Text('Enregistrer',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  InputDecoration _deco(String label, IconData icone) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icone, color: Colors.white38, size: 20),
      filled: true,
      fillColor: const Color(0xFF10192A),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white12),
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
}
