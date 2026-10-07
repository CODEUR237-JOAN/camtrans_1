import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import 'package:update_camtrans/services/service_ia.dart';

// =====================================================================
// COMBI — ASSISTANT IA VOCAL DE CAMTRANS
//
// « Combi » est le copilote conversationnel de l'application. Il est
// pensé comme un collègue bienveillant : chaleureux, concis (ses
// réponses sont lues à voix haute), et toujours dans le vouvoiement.
//
// Architecture (MVVM) :
//   - Service (cette classe) : génère dynamiquement le System Prompt
//     selon le rôle, dialogue avec le LLM via ServiceIA, nettoie le
//     texte pour la synthèse vocale, et pilote TTS/STT.
//   - Le System Prompt EST cloisonné (RBAC) : un client et un
//     transporteur ne parlent pas au même Combi.
//
// Deux règles non négociables :
//   1. Easter egg d'identité : si on demande à Combi qui l'a créé,
//      il répond EXACTEMENT « Mon créateur est l'ingénieur DONGMO JOAN. »
//   2. Cloisonnement : Combi refuse poliment (et réoriente) toute
//      demande hors de son périmètre métier.
// =====================================================================

enum EtatCombi { repos, ecoute, reflexion, parle, erreur }

final combiAIServiceProvider =
    StateNotifierProvider<CombiAIService, EtatCombi>((ref) {
  return CombiAIService(ref.read(serviceIAProvider));
});

class CombiAIService extends StateNotifier<EtatCombi> {
  final ServiceIA _serviceIA;

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _ttsPret = false;
  bool _sttPret = false;

  // Phrase exacte attendue par le cahier des charges (Easter egg).
  static const String reponseCreateur =
      "Mon créateur est l'ingénieur DONGMO JOAN.";

  // Mémoire courte de la conversation (format Claude : {role, content}).
  // On la borne pour éviter une facture et une latence qui enflent.
  final List<Map<String, dynamic>> _historique = [];
  static const int _maxEchanges = 12; // 6 allers-retours

  CombiAIService(this._serviceIA) : super(EtatCombi.repos) {
    _initTts();
  }

  // -------------------------------------------------------------------
  // INITIALISATION DE LA SYNTHÈSE VOCALE
  // -------------------------------------------------------------------
  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("fr-FR");
      await _tts.setSpeechRate(0.5); // débit posé, agréable à l'oreille
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _tts.setStartHandler(() => state = EtatCombi.parle);
      _tts.setCompletionHandler(() {
        if (state == EtatCombi.parle) state = EtatCombi.repos;
      });
      _tts.setErrorHandler((_) => state = EtatCombi.erreur);
      _ttsPret = true;
    } catch (_) {
      _ttsPret = false;
    }
  }

  // ===================================================================
  // GÉNÉRATION DYNAMIQUE DU SYSTEM PROMPT (cœur du cloisonnement RBAC)
  //
  // [role] attendu : 'client', 'transporteur' (ou 'admin' / null).
  // Le prompt change radicalement de périmètre selon le profil.
  // ===================================================================
  static String genererSystemPrompt(String? role) {
    const socle = '''
Tu es « Combi », l'assistant vocal de CamTrans, une plateforme de MISE EN RELATION directe entre des Clients et des Transporteurs routiers indépendants. L'application ne possède AUCUN véhicule en propre : elle est un tiers de confiance, comme Yango ou Uber Freight.

IDENTITÉ ET TON :
- Tu es chaleureux, bienveillant et empathique, comme un collègue de confiance.
- Tu vouvoies TOUJOURS l'utilisateur.
- Tes réponses sont LUES À VOIX HAUTE par un moteur de synthèse vocale.
  Sois concis, naturel et va droit au but. Utilise des phrases courtes.
  N'utilise JAMAIS de listes à puces, de tableaux ni de blocs de code.
- N'emploie AUCUN jargon technique. Parle comme un humain, pas comme un robot.
- Ta réponse doit être chaleureuse, empathique et naturelle à l'oreille.

RÈGLE ANTI-EMOJI ET ANTI-MARKDOWN (CRITIQUE POUR LA VOIX) :
- Ne génère JAMAIS d'emojis, de symboles Unicode décoratifs, ni de formatage
  Markdown (**, *, #, _, >, backticks). Ces caractères provoquent des erreurs
  de prononciation dans le lecteur vocal et doivent être proscrits sans exception.

VOCABULAIRE AUTORISÉ — RÈGLE ABSOLUE DE SUBSTITUTION :
- IL T'EST FORMELLEMENT INTERDIT d'utiliser les mots : Expédition, Expédier,
  Livreur, Colis postal, Messagerie, Bureau de tri.
- Utilise EXCLUSIVEMENT les termes : Course, Client, Transporteur, Marchandise,
  Véhicule, Déménagement, Remorquage, Mise en relation, Fret.

RÈGLE D'IDENTITÉ (ABSOLUE) :
- Si l'on te demande qui t'a créé, qui est ton créateur, qui t'a conçu ou
  développé, tu réponds EXACTEMENT, mot pour mot, sans rien ajouter :
  "$reponseCreateur"
- Tu ne mentionnes jamais une autre entreprise ou un autre modèle d'IA.
''';

    switch (role) {
      case 'transporteur':
        return '''$socle
TON RÔLE AUPRÈS DE CET UTILISATEUR : il est TRANSPORTEUR indépendant.
Tu es son COPILOTE. Tu peux l'aider UNIQUEMENT sur :
- accepter ou refuser les courses qui lui sont proposées ;
- la navigation et l'itinéraire vers le Client ou la destination ;
- la gestion des documents de son véhicule (validité) ;
- l'historique de ses revenus et de ses retraits ;
- ses abonnements et forfaits.

CLOISONNEMENT (IMPORTANT) :
- Tu ne crées PAS de mise en relation et tu ne simules pas de tarif
  pour un Client : ce n'est pas le rôle du Transporteur.
- Toute question hors de ce périmètre (fonctions Client, sujets généraux
  sans rapport avec CamTrans), tu la refuses poliment et tu réorientes
  vers ce que tu sais faire pour un Transporteur. Exemple de refus doux :
  « Je suis là pour vous accompagner dans vos courses et votre activité
  de Transporteur. Pour cela, je peux vous aider avec... ».
''';

      case 'client':
        return '''$socle
TON RÔLE AUPRÈS DE CET UTILISATEUR : il est CLIENT.
Tu es son ASSISTANT DE MISE EN RELATION. Tu peux l'aider UNIQUEMENT sur :
- créer une nouvelle demande de course (déménagement, remorquage, fret) ;
- estimer ou simuler le tarif d'une course ;
- suivre une course en cours et connaître son statut ;
- régler une course par Mobile Money (via Campay) ;
- contacter le Transporteur attribué à sa course.

CLOISONNEMENT (IMPORTANT) :
- Tu N'accèdes PAS aux fonctions réservées aux Transporteurs (accepter des
  courses, revenus, documents du véhicule, abonnements).
- Toute question hors de ce périmètre (sujets généraux sans rapport avec
  CamTrans, fonctions Transporteur), tu la refuses poliment et tu
  réorientes. Exemple de refus doux : « Je suis là pour vous aider à
  organiser vos courses et suivre vos mises en relation.
  Je peux par exemple vous aider à... ».
''';

      default:
        // Admin ou rôle inconnu : on reste prudent et généraliste CamTrans.
        return '''$socle
TON RÔLE : accueillir l'utilisateur et l'orienter dans l'application
CamTrans. Reste strictement sur les sujets liés à CamTrans. Si tu ne
connais pas encore le profil de la personne, propose-lui gentiment de
préciser si elle a besoin d'un Transporteur (Client) ou si elle souhaite
gérer ses courses (Transporteur), puis aide-la dans ce cadre.
''';
    }
  }

  // ===================================================================
  // RÉPONDRE À UN MESSAGE (texte) — pipeline complet
  //   message -> (Easter egg ?) -> System Prompt selon rôle -> LLM
  //           -> nettoyage pour la voix -> TTS
  // Retourne la réponse texte (brute, non nettoyée) pour l'affichage UI.
  // ===================================================================
  Future<String> repondre(String message, {String? role}) async {
    final texte = message.trim();
    if (texte.isEmpty) return '';

    state = EtatCombi.reflexion;

    // 1) Easter egg : court-circuit LLM pour garantir la phrase exacte.
    if (estQuestionCreateur(texte)) {
      _ajouterHistorique('user', texte);
      _ajouterHistorique('assistant', reponseCreateur);
      await parler(reponseCreateur);
      return reponseCreateur;
    }

    // 2) System Prompt dynamique selon le rôle (RBAC).
    final systeme = genererSystemPrompt(role);

    // 3) Appel LLM (Claude prioritaire, repli Gemini) via ServiceIA.
    String reponse;
    try {
      reponse = await _serviceIA.genererReponseContextuelle(
        systeme: systeme,
        message: texte,
        historiqueClaude: List<Map<String, dynamic>>.from(_historique),
      );
    } catch (_) {
      state = EtatCombi.erreur;
      const secours =
          "Je suis désolé, je n'arrive pas à répondre pour le moment.";
      await parler(secours);
      return secours;
    }

    // 4) Mémorisation (bornée).
    _ajouterHistorique('user', texte);
    _ajouterHistorique('assistant', reponse);

    // 5) Lecture à voix haute (texte nettoyé).
    await parler(reponse);

    return reponse;
  }

  // -------------------------------------------------------------------
  // DÉTECTION DE LA QUESTION « QUI T'A CRÉÉ ? »
  // Statique et pure → testable sans initialiser TTS/STT.
  // -------------------------------------------------------------------
  static bool estQuestionCreateur(String message) {
    final m = message.toLowerCase();
    // On cherche la présence d'un verbe de création associé à "toi/t'".
    final parleDeCreation = m.contains('créé') ||
        m.contains('cree') ||
        m.contains('créer') ||
        m.contains('creer') ||
        m.contains('conçu') ||
        m.contains('concu') ||
        m.contains('développé') ||
        m.contains('developpe') ||
        m.contains('fabriqué') ||
        m.contains('fabrique') ||
        m.contains('créateur') ||
        m.contains('createur') ||
        m.contains('inventé') ||
        m.contains('invente');
    final parleDeToi = m.contains("t'a") ||
        m.contains('ta ') ||
        m.contains(' toi') ||
        m.contains('tu es') ||
        m.contains("t'es") ||
        m.contains('ton ') ||
        m.contains('vous a');
    return parleDeCreation && parleDeToi;
  }

  // -------------------------------------------------------------------
  // NETTOYAGE DU TEXTE AVANT LA VOIX
  // Supprime markdown (**, *, `, #, _, >) et émojis : la TTS ne doit
  // JAMAIS prononcer « astérisque astérisque » ni des symboles.
  // -------------------------------------------------------------------
  static String nettoyerPourVoix(String texte) {
    var t = texte;

    // Markdown de mise en forme.
    t = t.replaceAll('**', '');
    t = t.replaceAll('__', '');
    t = t.replaceAll(RegExp(r'[*`_#>]'), '');

    // Liens markdown [texte](url) -> texte
    t = t.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]*\)'),
      (m) => m.group(1) ?? '',
    );

    // Émojis et pictogrammes (blocs Unicode usuels).
    t = t.replaceAll(
      RegExp(
        r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2190}-\u{21FF}\u{2B00}-\u{2BFF}\u{FE00}-\u{FE0F}\u{1F1E6}-\u{1F1FF}]',
        unicode: true,
      ),
      '',
    );

    // Espaces multiples et lignes vides superflues.
    t = t.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    t = t.replaceAll(RegExp(r'\n{2,}'), '\n');
    return t.trim();
  }

  // -------------------------------------------------------------------
  // SYNTHÈSE VOCALE
  // -------------------------------------------------------------------
  Future<void> parler(String texte) async {
    if (!_ttsPret) await _initTts();
    final propre = nettoyerPourVoix(texte);
    if (propre.isEmpty) {
      state = EtatCombi.repos;
      return;
    }
    try {
      await _tts.stop();
      state = EtatCombi.parle;
      await _tts.speak(propre);
    } catch (_) {
      state = EtatCombi.erreur;
    }
  }

  Future<void> stopParole() async {
    try {
      await _tts.stop();
    } catch (_) {}
    if (state == EtatCombi.parle) state = EtatCombi.repos;
  }

  // -------------------------------------------------------------------
  // RECONNAISSANCE VOCALE (une seule écoute)
  // Retourne la phrase reconnue, ou une chaîne vide.
  // -------------------------------------------------------------------
  Future<String> ecouterUneFois() async {
    if (!_sttPret) {
      _sttPret = await _speech.initialize();
    }
    if (!_sttPret) {
      state = EtatCombi.erreur;
      return '';
    }

    String resultat = '';
    state = EtatCombi.ecoute;

    await _speech.listen(
      onResult: (r) => resultat = r.recognizedWords,
      listenOptions: stt.SpeechListenOptions(
        localeId: 'fr_FR',
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );

    // On attend la fin de l'écoute (STT s'arrête sur silence/confirmation).
    while (_speech.isListening) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (state == EtatCombi.ecoute) state = EtatCombi.repos;
    return resultat.trim();
  }

  Future<void> stopEcoute() async {
    try {
      await _speech.stop();
    } catch (_) {}
    if (state == EtatCombi.ecoute) state = EtatCombi.repos;
  }

  // -------------------------------------------------------------------
  // CYCLE COMPLET : écouter -> répondre (vocal de bout en bout)
  // -------------------------------------------------------------------
  Future<String> dialoguerVocal({String? role}) async {
    final phrase = await ecouterUneFois();
    if (phrase.isEmpty) {
      state = EtatCombi.repos;
      return '';
    }
    return repondre(phrase, role: role);
  }

  // -------------------------------------------------------------------
  // GESTION DE LA MÉMOIRE DE CONVERSATION
  // -------------------------------------------------------------------
  void _ajouterHistorique(String role, String contenu) {
    _historique.add({"role": role, "content": contenu});
    while (_historique.length > _maxEchanges) {
      _historique.removeAt(0);
    }
  }

  void reinitialiser() {
    _historique.clear();
    state = EtatCombi.repos;
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    super.dispose();
  }
}
