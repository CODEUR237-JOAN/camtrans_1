import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_paiement.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/constantes/tailles.dart';
import 'package:update_camtrans/coeur/widgets/bouton_principal.dart';
import 'package:update_camtrans/coeur/etat/transporteur_provider.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';

class Portefeuille extends ConsumerWidget {
  const Portefeuille({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsRevenus = ref.watch(statsRevenusProvider);
    final fluxRevenus = ref.watch(fluxMesRevenusProvider);
    final solde = statsRevenus['total'] ?? 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Mon portefeuille"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(TaillesApp.margePage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: CouleursApp.degradePrincipal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Solde disponible",
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                        fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${solde.toStringAsFixed(0)} FCFA",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: _statistique(
                    "Cette semaine",
                    "${(statsRevenus['cetteSemaine'] ?? 0).toStringAsFixed(0)} FCFA",
                    Icons.date_range,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _statistique(
                    "Ce mois",
                    "${(statsRevenus['ceMois'] ?? 0).toStringAsFixed(0)} FCFA",
                    Icons.calendar_month,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              "Retrait",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            BoutonPrincipal(
              texte: "Retirer via Orange Money",
              icone: Icons.account_balance_wallet,
              auClic: () =>
                  _demanderRetrait(context, ref, "Orange Money", solde),
            ),
            const SizedBox(height: 15),
            BoutonPrincipal(
              texte: "Retirer via MTN Mobile Money",
              icone: Icons.phone_android,
              auClic: () =>
                  _demanderRetrait(context, ref, "MTN Mobile Money", solde),
            ),
            const SizedBox(height: 15),
            BoutonPrincipal(
              texte: "Virement bancaire",
              icone: Icons.account_balance,
              auClic: () =>
                  _demanderRetrait(context, ref, "Virement bancaire", solde),
            ),
            const SizedBox(height: 30),
            const Text(
              "Historique des transactions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            fluxRevenus.when(
                loading: () => const Center(child: LoaderPremium()),
                error: (err, _) => Text(
                    "Oups, impossible de charger vos transactions. ($err)"),
                data: (paiements) {
                  if (paiements.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                          child: Text("Aucune transaction.",
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.54)))),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: paiements.length,
                    itemBuilder: (context, index) {
                      final paiement = paiements[index];
                      return _transaction(
                        context,
                        paiement.courseId == 'RETRAIT'
                            ? "Retrait de fonds"
                            : "Paiement course",
                        paiement.courseId == 'RETRAIT'
                            ? paiement.reference
                            : "Via ${paiement.methodePaiement}",
                        paiement.montantNet > 0
                            ? "+${paiement.montantNet.toStringAsFixed(0)} FCFA"
                            : "${paiement.montantNet.toStringAsFixed(0)} FCFA",
                        paiement.montantNet > 0
                            ? CouleursApp.succes
                            : CouleursApp.erreur,
                        paiement.montantNet > 0
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                      );
                    },
                  );
                }),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  void _demanderRetrait(BuildContext context, WidgetRef ref, String methode,
      double soldeDisponible) {
    final TextEditingController montantController = TextEditingController();
    final TextEditingController compteController = TextEditingController();
    final TextEditingController mdpController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: CouleursApp.fondSombreSecondaire,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Demande de retrait",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    Text("Méthode : $methode",
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7))),
                    const SizedBox(height: 24),
                    TextField(
                      controller: compteController,
                      keyboardType: methode == "Virement bancaire"
                          ? TextInputType.text
                          : TextInputType.phone,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: methode == "Virement bancaire"
                            ? "IBAN / Numéro de compte"
                            : "Numéro de téléphone",
                        labelStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.54)),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.24)),
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: CouleursApp.primaire),
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: montantController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText:
                            "Montant à retirer (Max: ${soldeDisponible.toStringAsFixed(0)} FCFA)",
                        labelStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.54)),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.24)),
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: CouleursApp.primaire),
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: mdpController,
                      obscureText: true,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        labelStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.54)),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.24)),
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: CouleursApp.primaire),
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CouleursApp.primaire,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                final montantText =
                                    montantController.text.trim();
                                final compte = compteController.text.trim();
                                final mdp = mdpController.text;

                                if (montantText.isEmpty ||
                                    compte.isEmpty ||
                                    mdp.isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "N'oubliez pas de remplir tous les champs pour continuer.")));
                                  return;
                                }

                                final double? montant =
                                    double.tryParse(montantText);
                                if (montant == null || montant <= 0) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Ce montant ne semble pas correct.")));
                                  return;
                                }

                                if (montant > soldeDisponible) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Vous ne pouvez pas retirer plus que votre solde disponible.")));
                                  return;
                                }

                                setState(() => isLoading = true);

                                try {
                                  final authService =
                                      ref.read(serviceAuthentificationProvider);
                                  final currentUser = authService.utilisateur;

                                  if (currentUser == null ||
                                      currentUser.email == null) {
                                    throw Exception(
                                        "Nous avons perdu votre connexion. Veuillez vous reconnecter.");
                                  }

                                  // Reauthentifier (lance une erreur si mdp incorrect)
                                  await authService.reauthentifier(
                                      currentUser.email!, mdp);

                                  final transporteurId =
                                      ref.read(currentTransporteurIdProvider);
                                  final servicePaiement =
                                      ref.read(servicePaiementProvider);

                                  // Appeler l'API de paiement Campay pour faire le transfert
                                  await servicePaiement
                                      .initierRetraitMobileMoney(
                                    montant: montant,
                                    telephoneBeneficiaire: compte,
                                    description:
                                        "Retrait portefeuille CamTrans",
                                  );

                                  await FirebaseFirestore.instance
                                      .collection('paiements')
                                      .add({
                                    'transporteurId': transporteurId,
                                    'clientId': '',
                                    'courseId': 'RETRAIT',
                                    'montant': -montant,
                                    'montantNet': -montant,
                                    'devise': 'FCFA',
                                    'methodePaiement': methode,
                                    'numeroTransaction':
                                        'RET-${DateTime.now().millisecondsSinceEpoch}',
                                    'statut': 'succès',
                                    'datePaiement':
                                        DateTime.now().toIso8601String(),
                                    'paiementConfirme': true,
                                    'reference': 'Retrait vers $compte',
                                    'operateur': methode,
                                    'telephonePayeur': compte,
                                    'commentaire': 'Demande de retrait',
                                    'fraisTransaction': 0.0,
                                    'remboursementEffectue': false,
                                  });

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content:
                                          Text("Retrait effectué avec succès"),
                                      backgroundColor: CouleursApp.succes,
                                    ));
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    String messageErreur = e.toString();
                                    if (messageErreur
                                        .startsWith("Exception: ")) {
                                      messageErreur = messageErreur
                                          .replaceFirst("Exception: ", "");
                                    }
                                    showDialog(
                                        context: ctx,
                                        builder: (BuildContext dialogCtx) {
                                          return AlertDialog(
                                            title: const Row(
                                              children: [
                                                Icon(Icons.error_outline,
                                                    color: CouleursApp.erreur),
                                                SizedBox(width: 8),
                                                Text(
                                                    "Oups, le retrait a échoué",
                                                    style: TextStyle(
                                                        color:
                                                            CouleursApp.erreur,
                                                        fontSize: 18)),
                                              ],
                                            ),
                                            content: Text(messageErreur,
                                                style: const TextStyle(
                                                    color: Colors.white)),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(dialogCtx),
                                                child: Text("C'est noté",
                                                    style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ),
                                            ],
                                            backgroundColor:
                                                const Color(0xFF1A2235),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16)),
                                          );
                                        });

                                    // Vider les champs
                                    montantController.clear();
                                    compteController.clear();
                                    mdpController.clear();

                                    setState(() => isLoading = false);
                                  }
                                }
                              },
                        child: isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    strokeWidth: 2))
                            : Text("Confirmer le retrait",
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          });
        });
  }

  Widget _statistique(String titre, String valeur, IconData icone) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icone, color: CouleursApp.primaire, size: 35),
            const SizedBox(height: 12),
            Text(valeur,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            Text(titre, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _transaction(BuildContext context, String titre, String sousTitre,
      String montant, Color couleur, IconData icone) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: couleur.withValues(alpha: .15),
          child: Icon(icone, color: couleur),
        ),
        title: Text(titre,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        subtitle: Text(sousTitre,
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.54))),
        trailing: Text(
          montant,
          style: TextStyle(
              color: couleur, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
