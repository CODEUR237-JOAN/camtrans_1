# Journal des modifications — Passation pour agent IA

> **But de ce fichier :** permettre à un autre agent IA (ou développeur) de reprendre le travail sans contexte préalable. Tout ce qui a été fait, pourquoi, où, et ce qui reste.
> **Dernière mise à jour :** 2026-10-06.
> **Projet :** CamTrans — plateforme Flutter + Firebase de mise en relation client ↔ transporteur (Cameroun). Paiement Campay (Mobile Money), attribution auto (Cloud Function + OSRM), assistant IA (Claude + Gemini), chat, suivi GPS, espace admin.

---

## 0. Contexte & contraintes à connaître AVANT de coder

- **Stack :** Flutter/Dart, Firebase (Firestore, Auth, Storage, Cloud Functions v1), Riverpod, go_router. Code et commentaires **en français** (dossiers `fonctionnalites`, `services`, `modeles`, `coeur`).
- **CONTRAINTE FORTE — rester GRATUIT :** l'utilisateur (non-codeur) n'a **pas de carte bancaire**, donc **pas de plan payant** : ni Firebase **Blaze**, ni forfait Anthropic payant. Conséquence : **ne pas créer de nouvelles Cloud Functions** (Blaze requis). Privilégier les règles Firestore (gratuit) et le branchement d'écrans côté client. ⚠️ Les Cloud Functions existantes (`functions/index.js`) ne tournent probablement pas sans Blaze — à vérifier.
- **Environnement de dev de cette session :** Windows, PowerShell. Git a dû être installé (winget) ; il n'est pas toujours dans le PATH → utiliser `& "C:\Program Files\Git\cmd\git.exe"`. **Flutter n'est PAS installé ici** : aucune compilation/`flutter analyze` n'a pu être lancée. L'utilisateur teste sur une autre machine déjà configurée.
- **Git push :** l'environnement d'exécution de l'agent est non-interactif → le gestionnaire d'identifiants GitHub ne s'ouvre pas côté agent. **C'est l'utilisateur qui lance `git push`** dans son terminal. Identité de commit : `CODEUR237-JOAN` / `codeur633@gmail.com`.
- **Règles Firestore :** les modifier dans `firestore.rules` **ne suffit pas** — il faut les **DÉPLOYER** (Console Firebase → Firestore → Règles → Publier, gratuit). Pousser sur GitHub ≠ déployer.
- **`.env` :** gitignoré (jamais commité). Contient les clés (`CLAUDE_API_KEY`, `GEMINI_API_KEY`, Campay, Google Maps). `lib/coeur/constantes/api_keys.dart` est aussi gitignoré et nécessaire à la compilation.

---

## 1. Historique des commits de cette session (du plus ancien au plus récent)

### `1be68e3` — fix(ia) : réparer l'assistant Claude
**Fichiers :** `lib/services/service_ia.dart`, `.env.example`
**Problème :** l'assistant utilisait le modèle Claude `claude-3-haiku-20240307`, **retiré par Anthropic le 19/04/2026** → chaque appel échouait, et l'erreur était **masquée silencieusement** (bascule muette vers Gemini). Symptôme utilisateur : « la clé Claude ne marche pas alors qu'elle est intégrée ».
**Fait :**
- Modèle → constante `_nomModeleClaude = 'claude-haiku-4-5'` (successeur actif).
- Ajout en-tête HTTP `anthropic-dangerous-direct-browser-access: true` sur les 2 appels Claude (sinon CORS bloque sur Flutter Web).
- Erreurs Claude désormais tracées via `debugPrint` (au lieu d'être avalées) tout en gardant le secours Gemini.
- `CLAUDE_API_KEY` documentée dans `.env.example`.
**Archi (connu, NON corrigé) :** clés IA lues côté client → extractibles. Correctif propre = proxy Cloud Function (payant → reporté).

### `6933ba9` — fix(securite) : durcir les règles Firestore (gratuit)
**Fichier :** `firestore.rules`
- **Chat de course** `courses/{id}/messages` : était `allow read, write: if estConnecte()` (tout connecté pouvait lire/écrire le chat de n'importe quelle course). → restreint au client, au transporteur de la course, ou admin. (NB : l'app utilise en réalité la collection racine `messages`, pas cette sous-collection → zéro régression.)
- **Collection `transporteurs`** : le propriétaire ne peut plus modifier les champs sensibles `soldePortefeuille`, `documentsValides`, `revenusTotaux`, `noteMoyenne` (réservés admin/serveur) → empêche l'auto-crédit du portefeuille, l'auto-validation et le trucage. À la création : `documentsValides == false` et `soldePortefeuille == 0` forcés.
- **Laissé modifiable par le propriétaire** : `dateFinAbonnement` (l'abonnement est écrit côté client après paiement Campay ; sans serveur on ne peut pas le verrouiller — **risque résiduel assumé** : un transporteur pourrait prolonger son abonnement sans payer).

### `3d275de` — feat(ui) : brancher écrans statiques (paramètres client + historique transporteur)
**Fichiers :** `lib/fonctionnalites/client/parametres.dart`, `lib/fonctionnalites/transporteur/historique_courses.dart`
- **Paramètres client :** 3 tuiles avaient `onTap: () {}` (liens morts). Branchées : « Modifier le mot de passe » → `context.push(RoutesApplication.changerMotDePasse)` (écran existant) ; « Sécurité » → bottom sheet `_ouvrirSecurite()` (raccourci mot de passe + bascule biométrie + infos) ; « Confidentialité » → bottom sheet `_ouvrirConfidentialite()` (usage données, lien politique, demande suppression compte via mailto). Helpers ajoutés : `_afficherFeuille`, `_ligneFeuilleAction`, `_ligneFeuilleSwitch`, `_ligneFeuilleInfo`.
- **Historique transporteur :** le tap affichait un SnackBar « Détails bientôt disponibles ». → ouvre maintenant une bottom sheet `_FeuilleDetailsCourse` (itinéraire, statut, prix, paiement, véhicule, distance, client, note).

### `b67063e` — feat(entretien) : écran Entretien dynamique branché sur Firestore
**Fichiers :** `lib/modeles/entretien.dart` (nouveau), `lib/fonctionnalites/transporteur/entretien.dart` (réécrit), `lib/coeur/routes/routes.dart`, `lib/fonctionnalites/transporteur/tableau_de_bord_transporteur.dart`, `firestore.rules`
**Problème :** l'écran Entretien était 100 % mock (liste `entretiens` codée en dur, boutons SnackBar) ET **non accessible** (aucune route, aucun import ailleurs = code mort).
**Fait :**
- Nouveau modèle `Entretien` (`modeles/entretien.dart`) : `id, transporteurId, titre, type, dateDernier, dateProchain?, note, dateCreation` + `toMap`/`fromMap`/`copyWith` + getter `bientotDu`.
- Collection Firestore **`entretiens`** + règles : lecture/écriture limitées au transporteur propriétaire (ou admin). Ajoutées dans `firestore.rules`.
- Écran réécrit en `ConsumerStatefulWidget` nommé **`EcranEntretien`** (⚠️ renommé car l'ancien widget `Entretien` entrait en collision avec le modèle `Entretien`). Lecture temps réel via `ServiceFirestore.fluxCollectionCondition(collection:'entretiens', champ:'transporteurId', valeur: uid)`, tri côté client (évite un index composite). CRUD : ajout/édition via `_FormulaireEntretien` (bottom sheet avec titre, catégories ChoiceChip, dates via showDatePicker, note), suppression via swipe + confirmation. États chargement (`LoaderPremium`) / vide / erreur.
- **Rendu accessible :** route `RoutesApplication.entretien = "/entretien"` + `GoRoute` ; carte « Entretien » (et « Abonnement ») ajoutée dans la grille d'actions de `tableau_de_bord_transporteur.dart`.
**Pièges évités :** collision de noms (modèle vs widget) ; locale `DateFormat('dd MMM yyyy', 'fr')` retirée → `DateFormat('dd MMM yyyy')` car `initializeDateFormatting('fr')` n'est jamais appelé dans le projet (sinon crash runtime) ; `CouleursApp.primaire` vérifié `static const` (OK pour le `const Map<String,Color>`).

### `631e409` — feat(chat) : envoi et affichage d'images dans le chat
**Fichiers :** `lib/modeles/message_chat.dart`, `lib/fonctionnalites/chat/ecran_chat.dart`
**Problème :** le chat ne gérait que le texte ; l'envoi d'image affichait « à venir » (dans le chat *legacy* `client/ecran_chat.dart`, non utilisé).
**Fait :**
- Modèle `MessageChat` enrichi d'un champ `imageUrl` (+ getter `estImage`).
- Écran chat live (`chat/ecran_chat.dart`, celui routé via `/chat`) : bouton pièce jointe → bottom sheet Galerie/Appareil photo → `ImagePicker` → upload **Cloudinary** via `ServiceStockage.uploaderFichier(dossier:'chat/<courseId>')` → message `{expediteurId, texte:'', imageUrl, timestamp}`. Affichage des images dans les bulles (`CachedNetworkImage`) + visionneuse plein écran (`InteractiveViewer`), état d'envoi (spinner sur le bouton), gestion d'erreurs (SnackBar).
- Les messages sont dans la sous-collection `courses/{courseId}/messages` — **déjà sécurisée** par le commit `6933ba9` (participants + admin). Images sur Cloudinary (preset unsigned), aucune règle Firestore supplémentaire requise.
**NB :** `lib/fonctionnalites/client/ecran_chat.dart` (ancien chat, paramètre `transporteur`, contient encore le SnackBar « image à venir ») est **du code mort** — non importé/routé. À supprimer lors d'un nettoyage.

### `a09846d` — style(ui) : REBRAND BLEU + polish connexion
**Fichiers :** `lib/coeur/constantes/couleurs.dart`, `lib/fonctionnalites/authentification/connexion.dart`, `lib/fonctionnalites/client/parametres.dart`
**⚠️ CHANGEMENT GLOBAL DE MARQUE :** la charte passe du **teal #00C896** au **bleu #007ACC / #33AFFF** (décision utilisateur). Modifié dans `CouleursApp` : `primaire`, `primaireFonce`, `primaireClair`, `primaireNeon`, `accent`, `accentNeon`, et les dégradés `degradePrincipal`/`degradeSplash`/`degradeNeon`. Comme les écrans utilisent les tokens, le bleu se propage partout. Seul 1 dégradé teal était codé en dur (bandeau profil `parametres.dart`) → corrigé. **Le logo/icône (assets) restent teal** tant que l'utilisateur ne fournit pas de nouveaux fichiers.
Polish connexion : sous-titre humanisé, lueur logo ultra-douce, `maxLines+ellipsis` sur libellés sociaux.

### `2647b27` — style(ui) : polish parcours inscription
**Fichiers :** `choix_profil.dart`, `inscription_client.dart`, `inscription_transporteur.dart`
Accents français corrigés (choix_profil) ; sous-titres d'accueil humanisés sous les titres ; titres centrés. Écrans déjà bleu-ready via les tokens.
**Règle de travail UI (demande utilisateur) :** polish strictement couche présentation (`fonctionnalites/**`, `coeur/widgets`, `coeur/theme`, `coeur/constantes/couleurs.dart`) — JAMAIS services/modeles/etat/auth. `flutter analyze` à lancer par l'utilisateur (Flutter absent de la machine agent).

### `d1978c8` — style(ui) : rebrand bleu du flux « Créer une demande »
**Fichier :** `lib/fonctionnalites/client/creer_demande.dart`
Cet écran codait le vert-marque `#12B76A` / `#0E9456` en dur (orbes, sélection de marque, labels, ombres, **CTA principal**). Remplacé par le bleu charte `#007ACC` / `#005C99`. Le vert sémantique de succès (`CouleursApp.succes`, gamme Éco) est conservé. Structure/animations (glassmorphism, radar, haptics) intactes.

### `5b4a4e8` — style(ui) : polish tableau de bord client
**Fichier :** `lib/fonctionnalites/client/tableau_de_bord_client.dart`
Déjà 100 % basé sur les tokens → déjà bleu. Changements : badge de statut de la course active via `StatutCourse.libelle` (au lieu du code brut), séparateur « → » entre adresses de l'historique, suppression de la classe morte `_BoutonServiceRapide`.

### `ac45053` — style(ui) : rebrand bleu COMPLET
**Fichiers :** `resume_expedition_bottom_sheet.dart`, `carte_estimation_remorque.dart`
Derniers verts-marque codés en dur (flux demande) passés au bleu. **Vérifié : 0 occurrence de `#12B76A`/`#00C896`/`#06B6D4`/`#0E9456` dans tout `lib/`.** Le rebrand bleu est terminé et cohérent sur toute l'app. Le tableau de bord transporteur n'a nécessité aucun changement (déjà 100 % tokens).

### `3198844` + `86edc21` — fix(ui) : relecture écrans restants (lisibilité)
Relecture ciblée (scans : handlers morts, stubs, statuts bruts, couleur-marque, icônes invisibles) de suivi/paiement/portefeuille/notifications/admin. Résultats :
- **Aucun** handler mort, stub, statut brut affiché, ni vert-marque dans ces écrans (ils héritent du bleu via les tokens).
- **Bug icône invisible corrigé** (pattern `iconTheme` = couleur du fond) : `notifications.dart` (icône « tout marquer lu ») et `client/suivi_transport.dart` (bouton retour sur écran d'erreur) → passés en blanc.
- **Portefeuille** : solde « null FCFA » si donnée non prête → variable `solde` sécurisée + fallbacks ; cartes de transaction (fond sombre) texte sans couleur → illisible en thème clair → texte blanc.

**Reste (facultatif) :** relecture approfondie page par page de l'ADMIN (11 fichiers, ~5700 lignes dont `page_vue_ensemble.dart` 1260 l.) et de `ecran_paiement.dart` (564 l.) / panneau de suivi — non faite ligne à ligne (volumineux, non compilable ici). Ces écrans héritent déjà du bleu ; les scans n'y ont pas remonté de défaut bloquant. Point d'attention thème : plusieurs écrans codent un fond sombre en dur (`0xFF08111F`/`0xFF10192A`) avec du texte sans couleur explicite → vérifier la lisibilité en THÈME CLAIR (risque de texte sombre sur carte sombre). Le vert sémantique `CouleursApp.succes` (#10B981) est à CONSERVER.

## Fonctionnalité : Portefeuille Administrateur (Admin Wallet)

Revenus propres de la plateforme (frais d'abonnements + frais de plateforme sur les courses) + retraits. Commits `d92afe3` (étape 1) et `04a31d4` (étapes 2-3).

**Architecture (clé) :** le solde est **DÉRIVÉ**, pas stocké-et-crédité : `soldeDisponible = (Σ abonnements.montant + Σ paiements.fraisTransaction des courses) − Σ historique_retraits.montant`. Aucune modif du flux de paiement existant → compatible gratuit (pas de Cloud Function). Une copie cache (`soldeDisponible`/`revenusTotaux`) est écrite sur `admin/{uid}` lors du retrait, mais la source de vérité reste le calcul dérivé.

**Fichiers :**
- `modeles/retrait_admin.dart` (RetraitAdmin), `modeles/portefeuille_admin.dart` (getters `revenusTotaux`, `soldeDisponible`).
- `coeur/etat/admin_portefeuille_provider.dart` : `adminHistoriqueRetraitsProvider` (flux), `adminPortefeuilleProvider` (calcul réactif), `adminPortefeuilleActionsProvider.demanderRetrait(montant, methode, beneficiaire, statut)` — recalcule le solde, vérifie, écrit en **batch atomique** (entrée `historique_retraits` + cache `admin/{uid}`).
- `fonctionnalites/admin/pages/page_portefeuille_admin.dart` : écran (carte maîtresse bleue, 2 compteurs, historique + empty state, BottomSheet de retrait validé).
- Intégration : page index **10** du PageView dans `tableau_de_bord_admin.dart` + entrée « Mon Portefeuille » (section FINANCES) dans `sidebar_admin.dart`.
- `firestore.rules` : collection `historique_retraits` → `allow read, write: if estAdmin()`. **À redéployer** dans la Console Firebase.

**Limite connue :** le transfert d'argent réel (Mobile Money) passe par `servicePaiement.initierRetraitMobileMoney` **côté client** (identifiants Campay embarqués — même limite que le portefeuille transporteur). Virement bancaire = statut `en_attente` (traitement manuel). Sécurisation = Cloud Function (plan payant), reportée.

---

## 2. État de déploiement (IMPORTANT)

| Élément | Commité | Poussé GitHub | Déployé/Actif |
|---|---|---|---|
| Correctifs Dart (IA, UI, entretien) | ✅ | ⏳ (push par l'utilisateur) | effectif après rebuild de l'app |
| `firestore.rules` (durcissement + collection `entretiens`) | ✅ | ⏳ | ❌ **à publier dans la Console Firebase** |

➡️ **Tant que `firestore.rules` n'est pas publié dans la Console Firebase**, le durcissement sécurité n'est pas actif ET l'ajout d'entretien sera **refusé** (collection `entretiens` non autorisée).

---

## 3. Ce qui RESTE (issu de l'audit complet)

### Faisable gratuitement (côté client)
- ✅ **Envoi d'image dans le chat** — FAIT (commit `631e409`).
- **Nettoyage code mort** : supprimer `lib/fonctionnalites/client/ecran_chat.dart` (chat legacy non utilisé).
- **Couleurs codées en dur** (P2 UX) : plusieurs écrans utilisent `0xFF08111F` / `0xFF10192A` au lieu des tokens de thème → ne suivent pas le mode clair. (NB : le nouvel `EcranEntretien` reste en sombre codé en dur par cohérence avec ses écrans frères ; à harmoniser globalement plus tard.)

### Nécessite un serveur (plan Blaze/carte → BLOQUÉ pour l'instant)
- **Sécurité paiement (P0) :** aujourd'hui un client peut marquer une course « payée » sans payer (`service_paiement.dart` `_creerPaiementReussi` écrit côté client ; règles `courses`/`paiements` permissives). Identifiants Campay (`service_paiement.dart:34`) et retraits `/withdraw/` exécutés côté client → extractibles. Correctif = Cloud Functions (`onCall` + webhook Campay).
- **Crédit du portefeuille transporteur CASSÉ :** `service_paiement.dart:476-490` tente de créditer `soldePortefeuille` depuis la session du **client** → refusé par les règles Firestore (le client n'est pas propriétaire du doc transporteur), erreur avalée. Ne peut marcher que via une Cloud Function.
- **Proxy IA :** déplacer les clés Claude/Gemini côté serveur.
- **Règles `courses` (2.4) :** encore trop permissives (client/transporteur propriétaires peuvent modifier presque tous les champs). Durcir nécessite de connaître précisément les champs écrits par chaque rôle à chaque transition — risqué sans serveur pour la confirmation de paiement. Laissé en l'état pour ne pas casser le flux gratuit.

### Robustesse / technique
- `functions/index.js` : utilise l'OSRM public `router.project-osrm.org` (serveur démo, non fiable en prod) dans une boucle séquentielle (N+1). À remplacer par un OSRM hébergé ou l'API Table.
- Retrait Campay considéré réussi dès acceptation de la requête (pas de polling du statut final) : `service_paiement.dart:218`.

---

## 4. Références utiles pour l'agent suivant
- Audit sécurité complet détaillé : voir les 4 volets dans l'historique de conversation (QA/statique, sécurité backend Firebase, UI/UX, matrice P0/P1/P2).
- Modèles Claude valides (si on retouche l'IA) : `claude-haiku-4-5` (rapide/éco), `claude-sonnet-5-5`, `claude-opus-5-5`. **Ne jamais** réutiliser `claude-3-*` (retirés).
- Service Firestore générique : `lib/services/service_firestore.dart` (`ajouterDocument`, `modifierDocument`, `supprimerDocument`, `fluxCollectionCondition`, `fluxDocument`).
- UID utilisateur courant : `ref.read(serviceAuthentificationProvider).utilisateur?.uid`.

## Fonctionnalité : Assistant vocal turn-by-turn premium (commit 820d9eb)

Refonte de `lib/services/service_navigation_vocale.dart` (le service défaillant utilisé par le ViewModel `coeur/etat/suivi_provider.dart`). **API publique conservée** (`demarrerNavigation`, `mettreAJourPosition`, `arreterNavigation`, `basculerMute`, `estMute`) → aucun impact sur l'UI carte ni les ViewModels ; les améliorations sont actives immédiatement.

Décision : le projet n'a pas de dossier `core/services/` ; le service canonique est `lib/services/` (convention FR). J'ai refactorisé en place plutôt que créer un 3ᵉ service parallèle. NB : il existe un DOUBLON `lib/fonctionnalites/suivi_course/services/service_navigation_vocale.dart` (TTS simple, méthode `annoncer`) utilisé par `suivi_course_provider.dart` — non touché ; à unifier un jour.

Apports : TTS fr-FR débit 0.46 / pitch 1.05, `awaitSpeakCompletion`, QUEUE_FLUSH (interruption), Audio Focus iOS (`duckOthers` + `voicePrompt`) ; paliers anti-spam 500/100/20 m (flags réinitialisés par étape) ; `onLocationUpdate(Position, EtapeTrajet)` pour injection VM ; `announceRerouting()` (anti-spam 8 s) ; `nettoyerInstruction()` supprime le HTML avant TTS. Modèle d'étape = `EtapeTrajet` (service_routage.dart) = le « RouteStep » du projet.

### Rerouting câblé dans le ViewModel (commit 851793c)
`coeur/etat/suivi_provider.dart` : à chaque position du chauffeur, `_verifierDeviation()` calcule la distance point→tracé (projection équirectangulaire, projection sur segments). Hors-route si > 60 m confirmé sur 3 relevés consécutifs (anti-jitter), uniquement en phases de conduite (enRouteDepart / charge / enTransit), cooldown 15 s. Déclenche `_navVocale.announceRerouting()` + recalcul OSRM depuis la position vers la cible (client ou destination), puis `_navVocale.rafraichirItineraire(nouveau)`. Service vocal : ajout de `rafraichirItineraire(InfoTrajet)`.

## Correction des 3 bugs d'authentification (commit 071e433)

- **Bug 1 (champs vidés) : déjà OK.** Aucun `.clear()` dans les `catch` des vues auth ; `coeur/widgets/champ_texte.dart` utilise le `controleur` externe → le texte survit aux rebuilds. Amélioration réelle = messages d'erreur clairs.
- **Bug 2 (unicité).** `service_authentification.dart` : `inscriptionAvecVerifications({email, motDePasse, telephone})`. Email → FirebaseAuth + `_messageErreurAuth()` (ex: `email-already-in-use` → "Cet email est déjà utilisé"). Téléphone → réservation ATOMIQUE (transaction) dans la collection `index_telephones/{numeroNormalisé}` APRÈS création du compte (sinon les règles bloquent la lecture). Numéro pris → `AuthException` + rollback (`cred.user.delete()`). Classe `AuthException` (toString = message). Vues `inscription_client`/`inscription_transporteur` appellent cette méthode. Pas de vérif du mot de passe. **Règle Firestore ajoutée** : `index_telephones` (read si connecté ; create si `uid == auth.uid`). NB : ne détecte que les numéros enregistrés APRÈS déploiement (pas de migration des comptes existants sans Cloud Function).
- **Bug 3 (Google).** `connexionGoogle()` : crée `utilisateurs/{uid}` à la 1re connexion (`additionalUserInfo.isNewUser`), gère l'annulation (retourne `null`). Code correct pour `google_sign_in 6.2.2`. **À vérifier côté config** : SHA-1/SHA-256 dans Firebase Console + OAuth client (le code ne peut pas corriger une config manquante).

À redéployer : `firestore.rules` (contient maintenant `index_telephones`, `historique_retraits`, `entretiens`).

---

## 🗂️ RÉCAPITULATIF DE SESSION (2026-10-05) — pour reprise rapide par un autre agent

Contexte transverse (à relire en priorité) :
- Projet **Flutter + Firebase**, utilisateur **non-codeur** qui **compile sur une app mobile** (pas de PC) → changements natifs = à valider côté build.
- **Gratuit obligatoire** : pas de plan Blaze/payant → pas de nouvelles Cloud Functions ; privilégier règles Firestore + logique client.
- **Flutter absent de la machine agent** → impossible de lancer `flutter analyze`/`run` ici ; l'utilisateur (et une 2e session active) le font.
- **2 sessions travaillent en parallèle** sur le même repo → toujours `git fetch`+`merge origin/main` avant de pousser.
- `firestore.rules` **à redéployer** par l'utilisateur (Console Firebase) : contient `index_telephones`, `historique_retraits`, `entretiens`.
- **SHA-1** : le vrai blocage de **Google Sign-In ET de la double-auth SMS** (Phone Auth) côté Android. À enregistrer dans Firebase (une app lectrice de signature sur le tel donne le SHA-1).

Travaux de la session (du plus ancien au plus récent) :
1. **IA Claude** réparée (modèle retiré `claude-3-haiku` → `claude-haiku-4-5`, erreurs rendues visibles, en-tête CORS web).
2. **Sécurité Firestore** durcie (chat de course, champs sensibles transporteur).
3. **Écrans statiques branchés** : paramètres client (tuiles), historique transporteur (fiche détail), **écran Entretien** (modèle + collection + CRUD), **chat image** (Cloudinary).
4. **Rebrand bleu** complet (#007ACC/#33AFFF) via tokens + élimination du vert-marque + **nouveau logo** partout.
5. **Portefeuille Admin** (modèles + logique dérivée + écran + règle `historique_retraits` + intégration dashboard/sidebar).
6. **Assistant vocal turn-by-turn premium** (paliers 500/100/20, audio ducking, HTML clean) + **rerouting** (détection déviation + recalcul OSRM).
7. **3 bugs auth** : champs conservés, unicité email + **téléphone** (`index_telephones`, transaction), Google (profil 1re connexion).
8. **Système `LoaderPage`** unifié (chargements pleine page).
9. **Paramètres client opérationnels** : interrupteurs notifications (FCM réel), GPS (permission_handler), puis biométrie réelle.
10. **Moyens de paiement** (client) : écran réel (numéros Mobile Money, champ `moyensPaiement` sur le doc client). Commit `903eab0`.
11. **Paramètres TOTALEMENT fonctionnel** (commit `762d35b`) :
    - « À propos » → contenus **in-app** (`ecran_contenu_info.dart` + `ContenusLegaux`, markdown) au lieu des liens morts camtrans.cm ; « Noter l'app » corrigé.
    - **Biométrie réelle** : `local_auth`, `service_biometrie.dart`, verrou au splash (SÛR : jamais de blocage). **Config native ajoutée** : `MainActivity`→`FlutterFragmentActivity`, permissions `USE_BIOMETRIC`/`USE_FINGERPRINT`, dép `local_auth ^2.3.0`. ⚠️ nécessite `flutter pub get` + rebuild ; si le build mobile ne gère pas le natif local_auth, isoler/retirer ce commit.
12. **Assistant vocal « Combi »** (commit `e35d429`) :
    - `lib/services/combi_ai_service.dart` (`CombiAIService`, `combiAIServiceProvider`, `StateNotifier<EtatCombi>`). MVVM : le **System Prompt est généré dynamiquement** selon le rôle (`genererSystemPrompt(role)`).
    - **Cloisonnement RBAC** : *client* = assistant de réservation (créer demande, simuler prix, suivre, payer Mobile Money, contacter transporteur) ; *transporteur* = copilote logistique (accepter courses, GPS, documents véhicule, revenus, abonnements). Hors périmètre → refus poli + réorientation.
    - **Easter egg d'identité garanti hors LLM** : toute question « qui t'a créé ? » renvoie EXACTEMENT « Mon créateur est l'ingénieur DONGMO JOAN. » (court-circuit avant appel modèle, pour fiabilité).
    - Ton humanisé (chaleureux, vouvoiement, concis pour TTS, sans jargon). `nettoyerPourVoix()` retire markdown (`**`,`*`,`` ` ``,`#`,`_`,`>`, liens) + émojis (RegExp Unicode) avant `flutter_tts`. STT `fr_FR` une passe (`ecouterUneFois`), cycle complet `dialoguerVocal`, mémoire bornée (12 messages).
    - Nouvelle méthode `ServiceIA.genererReponseContextuelle({systeme, message, historiqueClaude})` : Claude prioritaire, **repli Gemini**, ne lève jamais d'exception vers l'UI.
    - **Branché dans l'UI** (commit `0244473`) : `lib/coeur/widgets/combi_widget.dart` = `BoutonCombi` (FAB dégradé) + `CombiSheet` (chat à bulles, micro **et** saisie texte, indicateur d'état, accueil selon rôle). Lit le rôle via `userRoleProvider` → `repondre(message, role: role)` : cloisonnement RBAC effectif côté UI. Remplace l'ancien bouton vocal sur les **dashboards client + transporteur** ; l'assistant de **navigation du suivi** (`ecran_suivi_course`) reste sur l'ancien `ServiceAssistantVocal` (intentions). À terme : unifier les deux.
    - **Tests** (`test/combi_ai_service_test.dart`) : logique pure rendue statique (`genererSystemPrompt`, `nettoyerPourVoix`, `estQuestionCreateur`) → testable sans canal natif. ✅ 11 tests verts + `flutter analyze` propre (commit `aa9663a`).
13. **Remorquage — cascade véhicule + lieux prédictifs** (commit `3209501`) :
    - `lib/services/service_donnees_vehicules.dart` : `ServiceDonneesVehicules` (mocké), map marque→modèles. `modelesPour`, `rechercherModeles`, `saisieLibreModele`.
    - `lib/services/service_lieux.dart` : `ServiceLieux` via **Nominatim** (OSM), `countrycodes=cm`, User-Agent requis, `LieuSuggestion(libelle, lat, lon)`. **Gratuit, sans carte**. Emplacement clé Google Places documenté dedans si facturation activée un jour.
    - `lib/coeur/widgets/champ_recherche_lieu.dart` : champ prédictif (debounce 500 ms, résultats inline + icône lieu, état vide). Utilisé pour la **destination** dans `creer_demande.dart` (renseigne aussi `latitudeArrivee`/`longitudeArrivee`).
    - `creer_demande.dart` : champ **Modèle** désormais en cascade (grisé tant qu'aucune marque ; chips des modèles de la marque ; saisie libre conservée pour `estimerMasseIA`). `_buildFloatingTextField` a un param `enabled`. Ancienne liste statique `_quartiersCameroun` supprimée.
    - ⚠️ Nominatim : politique d'usage ~1 req/s + User-Agent (OK pour mono-utilisateur mobile avec debounce). Nécessite permission INTERNET (déjà présente).
14. **Core Loop — clôture sécurisée par PIN** (commit `765231c`, ⛔ **ANNULÉ** par `git revert` `18e74b9` à la demande de l'utilisateur — le code PIN de livraison n'est plus utilisé ; `codePinCourse` reste dans le modèle mais n'est ni affiché ni vérifié) :
    - Audit : étapes 1-3 du cahier des charges **déjà en place** (modèle `Course` complet avec `clientId`/`transporteurId`/`codePinCourse`/`fondsDebloques` ; machine `StatutCourse` + `peutTransitionnerVers` ; création client (PIN 4 chiffres généré dans `resume_expedition_bottom_sheet`) ; acceptation transactionnelle + transitions dans `TransporteurActions` ; suivi client/transporteur en Streams). **Pas de renommage de statuts** (le brief proposait `en_recherche/acceptee/...`, l'app a un vocabulaire plus riche — conservé).
    - Manque comblé (ÉTAPE 4) : le PIN était généré mais jamais vérifié.
      - `transporteur_provider.dart` → `TransporteurActions.cloturerCourseAvecPin(courseId, pin)` : transaction atomique, valide le PIN, passe à `terminee` + `fondsDebloques` + `dateFin`.
      - `suivi_transporteur.dart` : le bouton « Terminer » ouvre une saisie de PIN (était « sans code PIN »).
      - `suivi_transport.dart` (client) : carte affichant le code de livraison pendant la course active.
    - ⚠️ Deux flux de clôture coexistent : `suivi_transporteur.dart` (sécurisé par PIN ✅) et `suivi_course/` (flux paiement, inchangé). À unifier un jour.
15. **Suivi temps réel premium « Yango »** (commit `dfc0650`) — sur `flutter_map`/OSRM (GRATUIT, **pas** Google Maps, qui exigerait une carte bancaire + réécriture) :
    - `carte_suivi_interactive.dart` : passé en `StatefulWidget`. **Animation** du marqueur véhicule (AnimationController + interpolation lat/lon → plus de saut) + **rotation** selon le cap `atan2`. **Auto-cadrage** `fitCamera(CameraFit.bounds(..., padding: 100))` pour garder véhicule+cible visibles. Polyligne premium (primaire + `borderStrokeWidth`).
    - `panneau_details_bottom_sheet.dart` : **ETA humanisé** « Votre transporteur arrive dans environ X min » (vue client) + **bouton `BoutonCombi`** intégré.
    - Déjà présent (conservé) : routage 2 phases `approche`/`trajet` + OSRM dans `suivi_course_provider.dart`.
    - ✅ **Photo + plaque chauffeur** câblées (commit `f54bfaa`) : `transporteurParIdProvider` (`FutureProvider.family` dans `transporteurs_provider.dart`) ; `panneau_details_bottom_sheet` passé en `ConsumerWidget`, affiche la photo réelle dans l'avatar + l'immatriculation sous le nom (vue client).
    - ℹ️ `ServiceLieux` a reçu l'injection d'un `http.Client` (session parallèle, pour tests) — rétro-compatible, `ServiceLieux()` inchangé.

Reste connu / pistes : unifier les 2 services vocaux (doublon `suivi_course/services`), supprimer `fix_theme.dart` (script jetable à la racine), brancher le bouton « Paramètres » du **profil transporteur** (encore `() {}`), sécuriser Campay/clés IA côté serveur (nécessite Blaze), durcir les règles `courses`/`paiements` (nécessite serveur pour la confirmation de paiement).
