import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/etat/admin_portefeuille_provider.dart';
import 'package:update_camtrans/coeur/widgets/loader_premium.dart';
import 'package:update_camtrans/modeles/retrait_admin.dart';
import 'package:update_camtrans/services/service_paiement.dart';

// =====================================================================
// ÉCRAN : Portefeuille Administrateur
//
// Revenus propres de la plateforme (abonnements + frais de courses) et
// retraits. Solde dérivé (revenus − retraits) via adminPortefeuilleProvider.
// =====================================================================
class PagePortefeuilleAdmin extends ConsumerWidget {
  const PagePortefeuilleAdmin({super.key});

  static final NumberFormat _fmt = NumberFormat('#,##0', 'en_US');
  static String fcfa(double v) => '${_fmt.format(v)} FCFA';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portefeuilleAsync = ref.watch(adminPortefeuilleProvider);
    final retraitsAsync = ref.watch(adminHistoriqueRetraitsProvider);

    return Container(
      color: const Color(0xFF08111F),
      child: SafeArea(
        child: portefeuilleAsync.when(
          loading: () => const Center(child: LoaderPremium()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Impossible de charger le portefeuille.\n$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54)),
            ),
          ),
          data: (portefeuille) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête humanisé
                const Text('Mon Portefeuille',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                const SizedBox(height: 6),
                const Text('Vos revenus générés par CamTrans ',
                    style: TextStyle(color: Colors.white54, fontSize: 15)),
                const SizedBox(height: 24),

                // Carte maîtresse
                _MasterCard(
                  solde: portefeuille.soldeDisponible,
                  onRetrait: portefeuille.soldeDisponible > 0
                      ? () => _ouvrirRetrait(
                          context, ref, portefeuille.soldeDisponible)
                      : null,
                ),
                const SizedBox(height: 16),

                // Compteurs de transparence
                Row(
                  children: [
                    Expanded(
                      child: _Compteur(
                        titre: 'Revenus Abonnements',
                        valeur: fcfa(portefeuille.revenusAbonnements),
                        icone: Icons.workspace_premium_outlined,
                        couleur: CouleursApp.primaire,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _Compteur(
                        titre: 'Revenus Courses',
                        valeur: fcfa(portefeuille.revenusCourses),
                        icone: Icons.local_shipping_outlined,
                        couleur: CouleursApp.accentNeon,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                const Text('Historique des retraits',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                retraitsAsync.when(
                  loading: () => const Center(child: LoaderPremium(size: 24)),
                  error: (err, _) => Text('Erreur : $err',
                      style: const TextStyle(color: Colors.white54)),
                  data: (retraits) => retraits.isEmpty
                      ? const _EtatVideRetraits()
                      : Column(
                          children: retraits
                              .map((r) => _LigneRetrait(retrait: r))
                              .toList(),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _ouvrirRetrait(BuildContext context, WidgetRef ref, double solde) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0C1524),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FeuilleRetraitAdmin(soldeDisponible: solde),
    );
  }
}

// ---------------------------------------------------------------------
// Carte maîtresse : solde + bouton de retrait (InkWell / ripple)
// ---------------------------------------------------------------------
class _MasterCard extends StatelessWidget {
  final double solde;
  final VoidCallback? onRetrait;
  const _MasterCard({required this.solde, this.onRetrait});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: CouleursApp.degradePrincipal,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CouleursApp.primaire.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text('Solde disponible',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              PagePortefeuilleAdmin.fcfa(solde),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1),
            ),
          ),
          const SizedBox(height: 22),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onRetrait,
              child: Opacity(
                opacity: onRetrait == null ? 0.5 : 1,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.north_east_rounded,
                          color: CouleursApp.primaireFonce, size: 20),
                      SizedBox(width: 10),
                      Text('Effectuer un retrait',
                          style: TextStyle(
                              color: CouleursApp.primaireFonce,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Compteur esthétique
// ---------------------------------------------------------------------
class _Compteur extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icone;
  final Color couleur;
  const _Compteur(
      {required this.titre,
      required this.valeur,
      required this.icone,
      required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10192A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: couleur, size: 20),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valeur,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          Text(titre,
              style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Ligne d'historique de retrait
// ---------------------------------------------------------------------
class _LigneRetrait extends StatelessWidget {
  final RetraitAdmin retrait;
  const _LigneRetrait({required this.retrait});

  @override
  Widget build(BuildContext context) {
    final enAttente = retrait.statut == 'en_attente';
    final echoue = retrait.statut == 'echoue';
    final couleur = echoue
        ? CouleursApp.erreur
        : enAttente
            ? CouleursApp.avertissement
            : CouleursApp.succes;
    final libelleStatut = echoue
        ? 'Échoué'
        : enAttente
            ? 'En attente'
            : 'Effectué';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10192A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: couleur.withValues(alpha: 0.15),
          child: Icon(Icons.north_east_rounded, color: couleur, size: 20),
        ),
        title: Text('− ${PagePortefeuilleAdmin.fcfa(retrait.montant)}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(retrait.methodePaiement,
                style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
            Text(DateFormat('dd/MM/yyyy – HH:mm').format(retrait.date),
                style: const TextStyle(color: Colors.white38, fontSize: 11.5)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: couleur.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(libelleStatut,
              style: TextStyle(
                  color: couleur, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// État vide
// ---------------------------------------------------------------------
class _EtatVideRetraits extends StatelessWidget {
  const _EtatVideRetraits();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: CouleursApp.primaire.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  color: CouleursApp.primaire, size: 46),
            ),
            const SizedBox(height: 18),
            const Text('Aucun retrait effectué pour le moment',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
                'Vos retraits apparaîtront ici dès que vous en effectuerez un.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white54, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// FEUILLE DE RETRAIT (BottomSheet) — formulaire validé
// =====================================================================
class _FeuilleRetraitAdmin extends ConsumerStatefulWidget {
  final double soldeDisponible;
  const _FeuilleRetraitAdmin({required this.soldeDisponible});

  @override
  ConsumerState<_FeuilleRetraitAdmin> createState() =>
      _FeuilleRetraitAdminState();
}

class _FeuilleRetraitAdminState extends ConsumerState<_FeuilleRetraitAdmin> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _montant = TextEditingController();
  final TextEditingController _beneficiaire = TextEditingController();
  String _methode = 'Orange Money';
  bool _enCours = false;

  static const List<String> _methodes = [
    'Orange Money',
    'MTN Mobile Money',
    'Virement bancaire',
  ];

  bool get _estMobileMoney => _methode != 'Virement bancaire';

  @override
  void dispose() {
    _montant.dispose();
    _beneficiaire.dispose();
    super.dispose();
  }

  Future<void> _confirmer() async {
    if (!_formKey.currentState!.validate()) return;
    final montant = double.parse(_montant.text.trim().replaceAll(',', '.'));
    final beneficiaire = _beneficiaire.text.trim();

    setState(() => _enCours = true);
    try {
      // 1. Mobile Money : transfert réel via Campay. Virement : traitement manuel.
      String statut = 'succes';
      if (_estMobileMoney) {
        await ref.read(servicePaiementProvider).initierRetraitMobileMoney(
              montant: montant,
              telephoneBeneficiaire: beneficiaire,
              description: 'Retrait portefeuille Admin CamTrans',
            );
      } else {
        statut = 'en_attente';
      }

      // 2. Enregistrement comptable atomique (contrôle du solde inclus).
      await ref.read(adminPortefeuilleActionsProvider).demanderRetrait(
            montant: montant,
            methode: _methode,
            beneficiaire: beneficiaire,
            statut: statut,
          );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(statut == 'en_attente'
            ? 'Demande de virement enregistrée (traitement manuel).'
            : 'Retrait effectué avec succès.'),
        backgroundColor: CouleursApp.succes,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _enCours = false);
      String msg = e.toString().replaceFirst('Exception: ', '');

      // Humanisation du message d'erreur pour éviter d'afficher des logs bruts (CORS, fetch, URI...)
      final msgLower = msg.toLowerCase();
      if (msgLower.contains('failed to fetch') ||
          msgLower.contains('socketexception') ||
          msgLower.contains('xmlhttprequest')) {
        msg =
            "Problème de connexion avec le service financier. Veuillez vérifier votre connexion internet et réessayer.";
      } else if (msgLower.contains('timeout') || msgLower.contains('délai')) {
        msg = "Le serveur a mis trop de temps à répondre. Veuillez réessayer.";
      } else if (msgLower.contains('corsproxy') ||
          msgLower.contains('campay') ||
          msgLower.contains('api/token')) {
        msg =
            "Le service de paiement est temporairement indisponible ou rejette la connexion. Veuillez réessayer plus tard.";
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A2235),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.error_outline, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Retrait impossible',
                style: TextStyle(color: Colors.white, fontSize: 17)),
          ]),
          content: Text(msg,
              style: const TextStyle(color: Colors.white70, height: 1.5)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('COMPRIS',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
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
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Effectuer un retrait',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                  'Disponible : ${PagePortefeuilleAdmin.fcfa(widget.soldeDisponible)}',
                  style: const TextStyle(
                      color: CouleursApp.primaire,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),

              // Méthode
              const Text('Moyen de paiement',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _methodes.map((m) {
                  final sel = _methode == m;
                  return ChoiceChip(
                    label: Text(m),
                    selected: sel,
                    onSelected: (_) => setState(() => _methode = m),
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

              // Montant
              TextFormField(
                controller: _montant,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration:
                    _deco('Montant à retirer (FCFA)', Icons.payments_outlined),
                validator: (v) {
                  final t = (v ?? '').trim().replaceAll(',', '.');
                  final m = double.tryParse(t);
                  if (m == null || m <= 0) return 'Montant invalide';
                  if (m > widget.soldeDisponible) return 'Solde insuffisant';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Bénéficiaire
              TextFormField(
                controller: _beneficiaire,
                keyboardType:
                    _estMobileMoney ? TextInputType.phone : TextInputType.text,
                style: const TextStyle(color: Colors.white),
                decoration: _deco(
                  _estMobileMoney
                      ? 'Numéro de téléphone'
                      : 'IBAN / Numéro de compte',
                  _estMobileMoney
                      ? Icons.phone_outlined
                      : Icons.account_balance_outlined,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Champ obligatoire'
                    : null,
              ),
              const SizedBox(height: 24),

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
                  onPressed: _enCours ? null : _confirmer,
                  child: _enCours
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Confirmer le retrait',
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
