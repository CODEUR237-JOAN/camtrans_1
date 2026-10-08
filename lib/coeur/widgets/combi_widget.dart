import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:update_camtrans/coeur/constantes/couleurs.dart';
import 'package:update_camtrans/coeur/etat/utilisateur_provider.dart';
import 'package:update_camtrans/services/combi_ai_service.dart';

// =====================================================================
// COMBI — WIDGETS D'INTERFACE
//
// - [BoutonCombi] : le bouton flottant (micro) qui ouvre l'assistant.
// - [CombiSheet]  : la feuille de conversation (bulles) pilotée par
//   `combiAIServiceProvider`. Le rôle (client/transporteur) est lu via
//   `userRoleProvider` et transmis au service, qui cloisonne la réponse.
//
// Deux entrées possibles pour l'utilisateur : le micro (vocal) OU la
// saisie texte. La réponse de Combi est lue à voix haute par le service.
// =====================================================================

class BoutonCombi extends ConsumerWidget {
  /// Mode mini (pour s'insérer dans une barre de navigation).
  final bool compact;
  const BoutonCombi({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => _ouvrir(context),
      icon: const Icon(
        Icons.speaker_notes_rounded,
        color: CouleursApp.primaire,
        size: 28,
      ),
    );
  }

  void _ouvrir(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CombiSheet(),
    );
  }
}

// ---------------------------------------------------------------------
// Message affiché dans la conversation.
// ---------------------------------------------------------------------
class _MessageCombi {
  final bool deLUtilisateur;
  final String texte;
  const _MessageCombi(this.deLUtilisateur, this.texte);
}

class CombiSheet extends ConsumerStatefulWidget {
  const CombiSheet({super.key});

  @override
  ConsumerState<CombiSheet> createState() => _CombiSheetState();
}

class _CombiSheetState extends ConsumerState<CombiSheet> {
  final List<_MessageCombi> _messages = [];
  final TextEditingController _champ = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _accueilAffiche = false;

  @override
  void dispose() {
    _champ.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String? get _role => ref.read(userRoleProvider).valueOrNull;

  // Message d'accueil chaleureux selon le profil.
  void _afficherAccueilSiBesoin() {
    if (_accueilAffiche) return;
    _accueilAffiche = true;
    final role = _role;
    String accueil;
    if (role == 'transporteur') {
      accueil = "Bonjour, je suis Combi, votre copilote. "
          "Je peux vous aider avec vos courses, la navigation, "
          "vos documents, vos revenus ou vos abonnements.";
    } else if (role == 'client') {
      accueil = "Bonjour, je suis Combi, votre assistant. "
          "Je peux organiser une mise en relation, estimer un prix, "
          "suivre votre course ou vous aider à payer.";
    } else {
      accueil = "Bonjour, je suis Combi, l'assistant de CamTrans. "
          "Comment puis-je vous aider ?";
    }
    _messages.add(_MessageCombi(false, accueil));
  }

  void _defilerEnBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _envoyer(String texte) async {
    final t = texte.trim();
    if (t.isEmpty) return;
    final service = ref.read(combiAIServiceProvider.notifier);

    setState(() {
      _messages.add(_MessageCombi(true, t));
      _champ.clear();
    });
    _defilerEnBas();

    final reponse = await service.repondre(t, role: _role);

    if (!mounted) return;
    setState(() => _messages.add(_MessageCombi(false, reponse)));
    _defilerEnBas();
  }

  Future<void> _ecouter() async {
    final service = ref.read(combiAIServiceProvider.notifier);
    final etat = ref.read(combiAIServiceProvider);

    // Si Combi parle, on l'interrompt ; sinon on écoute.
    if (etat == EtatCombi.parle) {
      await service.stopParole();
      return;
    }
    if (etat == EtatCombi.ecoute) {
      await service.stopEcoute();
      return;
    }

    final phrase = await service.ecouterUneFois();
    if (phrase.isNotEmpty) {
      await _envoyer(phrase);
    }
  }

  @override
  Widget build(BuildContext context) {
    _afficherAccueilSiBesoin();
    final etat = ref.watch(combiAIServiceProvider);
    final hauteur = MediaQuery.of(context).size.height * 0.78;
    final clavier = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: clavier),
      child: Container(
        height: hauteur,
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            _entete(etat),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _bulle(_messages[i]),
              ),
            ),
            _indicateurEtat(etat),
            _barreSaisie(etat),
          ],
        ),
      ),
    );
  }

  Widget _entete(EtatCombi etat) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              gradient: CouleursApp.degradePrincipal,
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.magic_star_copy,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Combi",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                Text("Votre assistant CamTrans",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _bulle(_MessageCombi m) {
    final estUser = m.deLUtilisateur;
    return Align(
      alignment: estUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        decoration: BoxDecoration(
          gradient: estUser ? CouleursApp.degradePrincipal : null,
          color: estUser ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(estUser ? 16 : 4),
            bottomRight: Radius.circular(estUser ? 4 : 16),
          ),
        ),
        child: Text(
          m.texte,
          style: TextStyle(
            color:
                estUser ? Colors.white : Colors.white.withValues(alpha: 0.92),
            fontSize: 15,
            height: 1.35,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _indicateurEtat(EtatCombi etat) {
    String? txt;
    Color couleur = CouleursApp.primaireNeon;
    switch (etat) {
      case EtatCombi.ecoute:
        txt = "Je vous écoute…";
        break;
      case EtatCombi.reflexion:
        txt = "Combi réfléchit…";
        break;
      case EtatCombi.parle:
        txt = "Combi répond…";
        couleur = CouleursApp.succes;
        break;
      case EtatCombi.erreur:
        txt = "Un souci est survenu, réessayez.";
        couleur = CouleursApp.erreur;
        break;
      case EtatCombi.repos:
        txt = null;
        break;
    }
    if (txt == null) return const SizedBox(height: 2);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: couleur),
          ),
          const SizedBox(width: 10),
          Text(txt, style: TextStyle(color: couleur, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _barreSaisie(EtatCombi etat) {
    final occupe = etat == EtatCombi.reflexion;
    final enEcoute = etat == EtatCombi.ecoute;
    final parle = etat == EtatCombi.parle;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _champ,
                enabled: !occupe,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.send,
                onSubmitted: _envoyer,
                decoration: InputDecoration(
                  hintText: "Écrivez à Combi…",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: occupe ? null : _ecouter,
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  gradient: CouleursApp.degradePrincipal,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  (enEcoute || parle) ? Icons.stop : Iconsax.microphone_2_copy,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ).animate(target: enEcoute ? 1 : 0).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.12, 1.12),
                duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
