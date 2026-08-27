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

  /// A appeler apres la connexion de l utilisateur
  void demarrer({required String role}) {
    _collection = role == 'transporteur' ? 'transporteurs' : 'clients';
    WidgetsBinding.instance.addObserver(this);
    _setEnLigne(true);
  }

  /// A appeler lors de la deconnexion
  void arreter() {
    _setEnLigne(false);
    WidgetsBinding.instance.removeObserver(this);
    _collection = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setEnLigne(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _setEnLigne(false);
        break;
    }
  }

  void _setEnLigne(bool enLigne) {
    final user = _auth.currentUser;
    final collection = _collection;
    if (user == null || collection == null) return;

    final donnees = <String, dynamic>{
      'estEnLigne': enLigne,
      'derniereConnexion': FieldValue.serverTimestamp(),
    };

    _firestore.collection(collection).doc(user.uid).update(donnees).catchError((_) {});
  }
}
