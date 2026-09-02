import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

/// Service de presence : met a jour estEnLigne dans Firestore
/// selon l etat du cycle de vie de l application.
class ServicePresence with WidgetsBindingObserver {
  static final ServicePresence _instance = ServicePresence._internal();
  factory ServicePresence() => _instance;
  ServicePresence._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _collection; // 'clients' ou 'transporteurs'
  Timer? _heartbeatTimer;

  /// A appeler apres la connexion de l utilisateur
  void demarrer({required String role}) {
    _collection = role == 'transporteur' ? 'transporteurs' : 'clients';
    WidgetsBinding.instance.addObserver(this);
    _setEnLigne(true);
    _demarrerHeartbeat();
  }

  /// A appeler lors de la deconnexion
  Future<void> arreter() async {
    _arreterHeartbeat();
    await _setEnLigne(false);
    WidgetsBinding.instance.removeObserver(this);
    _collection = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("📱 Changement d'état de l'application : $state");
    switch (state) {
      case AppLifecycleState.resumed:
        _setEnLigne(true);
        _demarrerHeartbeat();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _arreterHeartbeat();
        _setEnLigne(false);
        break;
    }
  }

  void _demarrerHeartbeat() {
    _arreterHeartbeat();
    // Met à jour la dernière connexion toutes les 3 minutes pour indiquer que l'app est toujours ouverte
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _pingPresence();
    });
  }

  void _arreterHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _pingPresence() {
    final user = _auth.currentUser;
    final collection = _collection;
    if (user == null || collection == null) {
      debugPrint("⚠️ Heartbeat ignoré : user=$user, collection=$collection");
      return;
    }
    
    debugPrint("💓 Envoi du heartbeat pour ${user.uid} dans $collection...");
    _firestore.collection(collection).doc(user.uid).update({
      'derniereConnexion': FieldValue.serverTimestamp(),
      'estEnLigne': true,
    }).then((_) {
      debugPrint("✅ Heartbeat réussi !");
    }).catchError((e) {
      debugPrint("❌ Erreur Heartbeat : $e");
    });
  }

  Future<void> _setEnLigne(bool enLigne) async {
    final user = _auth.currentUser;
    final collection = _collection;
    if (user == null || collection == null) return;

    debugPrint("🔄 _setEnLigne($enLigne) pour ${user.uid} dans $collection...");

    final donnees = <String, dynamic>{
      'estEnLigne': enLigne,
      'derniereConnexion': FieldValue.serverTimestamp(),
    };

    await _firestore.collection(collection).doc(user.uid).update(donnees).then((_) {
      debugPrint("✅ _setEnLigne($enLigne) réussi !");
    }).catchError((e) {
      debugPrint("❌ Erreur _setEnLigne($enLigne) : $e");
    });
  }
}
