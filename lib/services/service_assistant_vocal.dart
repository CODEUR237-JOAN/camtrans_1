import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:update_camtrans/services/service_ia.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/coeur/etat/demande_expedition_provider.dart';
import 'package:update_camtrans/services/service_gps.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';

enum EtatAssistant { repos, veille, ecoute, traitement, parle, erreur }

final serviceAssistantVocalProvider = StateNotifierProvider<ServiceAssistantVocal, EtatAssistant>((ref) {
  return ServiceAssistantVocal(ref, ref.read(serviceIAProvider));
});

class ServiceAssistantVocal extends StateNotifier<EtatAssistant> {
  final Ref _ref;
  final ServiceIA _serviceIA;
  
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isInitialized = false;
  
  String texteCourant = "";
  void Function(String)? onTextChanged;
  void Function(String)? onNavigate;

  ServiceAssistantVocal(this._ref, this._serviceIA) : super(EtatAssistant.repos) {
    _initTTS();
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("fr-FR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      if (state == EtatAssistant.parle) {
        if (_doitRelancerVeille) {
          _doitRelancerVeille = false;
          _demarrerVeille();
        } else if (_doitRelancerEcouteActive) {
          _doitRelancerEcouteActive = false;
          demarrerEcoute(isWakeWord: false);
        } else {
          state = EtatAssistant.repos;
          texteCourant = "";
        }
      }
    });
  }

  bool _doitRelancerVeille = false;
  bool _doitRelancerEcouteActive = false;

  /// Active la veille (écoute continue pour détecter "CamTrans")
  Future<void> _demarrerVeille() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' && state == EtatAssistant.veille) {
            // Relancer la veille en boucle tant qu'on est en état veille
            _speech.listen(onResult: _onResultVeille, localeId: 'fr_FR', cancelOnError: true, listenMode: stt.ListenMode.dictation);
          }
        },
        onError: (error) {
          // Ignorer les timeouts en veille et relancer
          if (state == EtatAssistant.veille) {
             _speech.listen(onResult: _onResultVeille, localeId: 'fr_FR', cancelOnError: true, listenMode: stt.ListenMode.dictation);
          }
        }
      );
    }

    if (_isInitialized) {
      state = EtatAssistant.veille;
      texteCourant = "En veille (Dites 'CamTrans')";
      onTextChanged?.call(texteCourant);
      await _flutterTts.stop();
      _speech.listen(onResult: _onResultVeille, localeId: 'fr_FR', cancelOnError: true, listenMode: stt.ListenMode.dictation);
    }
  }

  void _onResultVeille(val) {
    final text = val.recognizedWords.toLowerCase();
    if (text.contains("camtrans") || text.contains("cam trans")) {
      _speech.stop();
      _declencherWakeWord();
    }
  }

  Future<void> _declencherWakeWord() async {
    state = EtatAssistant.traitement;
    final user = _ref.read(serviceAuthentificationProvider).utilisateur;
    String nom = user?.displayName ?? "Monsieur/Madame";
    String salutation = "Bonjour $nom, que voulez-vous ?";
    
    texteCourant = salutation;
    onTextChanged?.call(texteCourant);
    
    state = EtatAssistant.parle;
    _doitRelancerEcouteActive = true;
    await _flutterTts.speak(salutation);
  }

  /// Démarre l'écoute active d'une requête utilisateur
  Future<void> demarrerEcoute({bool isWakeWord = false}) async {
    if (isWakeWord) {
      await _demarrerVeille();
      return;
    }

    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' && state == EtatAssistant.ecoute) {
            _traiterTexteCommande();
          }
        },
        onError: (errorNotification) {
          state = EtatAssistant.erreur;
          texteCourant = "Erreur micro: ${errorNotification.errorMsg}";
          onTextChanged?.call(texteCourant);
          Future.delayed(const Duration(seconds: 2), () {
            state = EtatAssistant.repos;
            texteCourant = "";
            onTextChanged?.call(texteCourant);
          });
        },
      );
    }

    if (_isInitialized) {
      texteCourant = "J'écoute...";
      onTextChanged?.call(texteCourant);
      state = EtatAssistant.ecoute;
      
      await _flutterTts.stop();

      _speech.listen(
        onResult: (val) {
          texteCourant = val.recognizedWords;
          onTextChanged?.call(texteCourant);
        },
        localeId: 'fr_FR',
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      );
    }
  }

  Future<void> arreterEcoute() async {
    if (state == EtatAssistant.ecoute) {
      await _speech.stop();
      await _traiterTexteCommande();
    } else if (state == EtatAssistant.parle || state == EtatAssistant.veille) {
      await _speech.stop();
      await _flutterTts.stop();
      state = EtatAssistant.repos;
      texteCourant = "";
      onTextChanged?.call(texteCourant);
    }
  }

  Future<void> _traiterTexteCommande() async {
    if (texteCourant.isEmpty || texteCourant == "J'écoute..." || texteCourant == "En veille (Dites 'CamTrans')") {
      state = EtatAssistant.repos;
      texteCourant = "";
      onTextChanged?.call(texteCourant);
      return;
    }

    state = EtatAssistant.traitement;
    final phrase = texteCourant;
    texteCourant = "Analyse...";
    onTextChanged?.call(texteCourant);

    try {
      final jsonResponse = await _serviceIA.analyserIntentionVocale(phrase);
      
      String reponseVocale = jsonResponse["reponse_vocale"] ?? "Je n'ai pas compris.";
      bool complet = jsonResponse["complet"] ?? false;
      String intention = jsonResponse["intention"] ?? "INCONNU";

      if (intention == "CREER_COURSE") {
        if (complet) {
          // Lancer la création autonome
          await _creerCourseAutonome(jsonResponse);
        } else {
          // Rebond pour demander les infos manquantes
          _doitRelancerEcouteActive = true; 
        }
      } else {
        // Intention inconnue, on répond juste
      }

      state = EtatAssistant.parle;
      texteCourant = reponseVocale;
      onTextChanged?.call(texteCourant);
      await _flutterTts.speak(reponseVocale);

    } catch (e) {
      state = EtatAssistant.erreur;
      texteCourant = "Erreur de compréhension.";
      onTextChanged?.call(texteCourant);
      Future.delayed(const Duration(seconds: 3), () {
        state = EtatAssistant.repos;
      });
    }
  }

  Future<void> _creerCourseAutonome(Map<String, dynamic> data) async {
    final clientAuth = _ref.read(serviceAuthentificationProvider).utilisateur;
    if (clientAuth == null) return;

    final String depart = data["depart"] ?? "";
    final String arrivee = data["arrivee"] ?? "";
    final String cat = data["marchandise"] ?? "Standard";

    // --- GPS et Geocoding ---
    final serviceGps = _ref.read(serviceGpsProvider);
    
    // 1. Position actuelle (Départ)
    final positionDepart = await serviceGps.obtenirPositionActuelle();
    double latDepart = positionDepart?.latitude ?? 3.8480; // Yaoundé par défaut si refusé
    double lngDepart = positionDepart?.longitude ?? 11.5021;
    String adresseDepartReelle = depart;
    if (depart.isEmpty || depart.toLowerCase() == "ici") {
      adresseDepartReelle = await serviceGps.obtenirAdresse(latitude: latDepart, longitude: lngDepart);
    }

    // 2. Géocodage de l'arrivée
    double latArrivee = 3.8480;
    double lngArrivee = 11.5021;
    final locArrivee = await serviceGps.obtenirCoordonnees(arrivee);
    if (locArrivee != null) {
      latArrivee = locArrivee.latitude;
      lngArrivee = locArrivee.longitude;
    }

    // 3. Calcul de la distance
    double distanceCourse = serviceGps.calculerDistance(
      latitudeDepart: latDepart, 
      longitudeDepart: lngDepart, 
      latitudeArrivee: latArrivee, 
      longitudeArrivee: lngArrivee
    );
    if (distanceCourse < 1.0) distanceCourse = 5.0; // Distance minimum

    // Injection dans le provider de demande
    final notifier = _ref.read(demandeExpeditionProvider.notifier);
    notifier.setCategorieService(cat);
    notifier.setDepart(adresseDepartReelle);
    notifier.setDestination(arrivee);
    notifier.setLatitudeDepart(latDepart);
    notifier.setLongitudeDepart(lngDepart);
    notifier.setLatitudeArrivee(latArrivee);
    notifier.setLongitudeArrivee(lngArrivee);
    
    // Création Firestore de la course
    final serviceFirestore = _ref.read(serviceFirestoreProvider);
    final String docId = "C-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";
    final String codeSuivi = docId;

    final Course nouvelleCourse = Course(
      id: docId, // généré localement
      clientId: clientAuth.uid,
      transporteurId: "",
      nomClient: clientAuth.displayName ?? "Client",
      nomTransporteur: "",
      telephoneClient: "",
      telephoneTransporteur: "",
      adresseDepart: adresseDepartReelle,
      adresseArrivee: arrivee,
      latitudeDepart: latDepart,
      longitudeDepart: lngDepart,
      latitudeArrivee: latArrivee,
      longitudeArrivee: lngArrivee,
      distanceKm: distanceCourse,
      volumeM3: 0.0,
      poidsKg: 0.0,
      typeVehicule: "",
      typeMarchandise: cat,
      prixEstime: 5000,
      prixFinal: 0,
      modePaiement: "cash",
      paiementEffectue: false,
      statut: StatutCourse.recherche,
      description: "Commande vocale",
      photos: const [],
      dateCreation: DateTime.now(),
      fragile: false,
      aideChargement: false,
      aideDechargement: false,
      codeSuivi: codeSuivi,
      noteClient: 0.0,
      noteTransporteur: 0.0,
      commentaireClient: "",
      commentaireTransporteur: "",
      scoreIA: 0.0,
      vehiculeRecommandeIA: "",
      volumeEstimeIA: 0.0,
      conseilIA: "",
      categorieService: cat,
      optionGamme: "",
      detailsSpecifiques: "",
      distanceApprocheKm: 0.0,
      tempsApprocheMin: 0,
      candidats: const [],
      indexCandidatActuel: 0,
      codePinLivraison: "",
      fondsDebloques: false,
    );

    await serviceFirestore.ajouterDocument(
      collection: 'courses',
      id: docId,
      donnees: nouvelleCourse.toMap(),
    );

    // Redirection automatique via callback de navigation
    onNavigate?.call('/recherche-chauffeur/$docId');
  }

  void reset() {
    _speech.stop();
    _flutterTts.stop();
    state = EtatAssistant.repos;
    texteCourant = "";
    onTextChanged?.call(texteCourant);
  }
}
