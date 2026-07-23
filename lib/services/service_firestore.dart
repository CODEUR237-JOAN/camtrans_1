import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final serviceFirestoreProvider = Provider<ServiceFirestore>((ref) {
  return ServiceFirestore();
});

class ServiceFirestore {
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  // ===========================
  // Collections
  // ===========================

  CollectionReference<Map<String, dynamic>>
  get utilisateurs =>
      _db.collection("utilisateurs");

  CollectionReference<Map<String, dynamic>>
  get clients =>
      _db.collection("clients");

  CollectionReference<Map<String, dynamic>>
  get transporteurs =>
      _db.collection("transporteurs");

  CollectionReference<Map<String, dynamic>>
  get courses =>
      _db.collection("courses");

  CollectionReference<Map<String, dynamic>>
  get paiements =>
      _db.collection("paiements");

  CollectionReference<Map<String, dynamic>>
  get notifications =>
      _db.collection("notifications");

  // ===========================
  // Ajouter un document
  // ===========================

  Future<void> ajouterDocument({
    required String collection,
    required String id,
    required Map<String, dynamic> donnees,
  }) async {
    await _db
        .collection(collection)
        .doc(id)
        .set(donnees);
  }

  // ===========================
  // Modifier un document
  // ===========================

  Future<void> modifierDocument({
    required String collection,
    required String id,
    required Map<String, dynamic> donnees,
  }) async {
    await _db
        .collection(collection)
        .doc(id)
        .update(donnees);
  }

  // ===========================
  // Supprimer un document
  // ===========================

  Future<void> supprimerDocument({
    required String collection,
    required String id,
  }) async {
    await _db
        .collection(collection)
        .doc(id)
        .delete();
  }

  // ===========================
  // Lire un document
  // ===========================

  Future<DocumentSnapshot<Map<String, dynamic>>>
  lireDocument({
    required String collection,
    required String id,
  }) async {
    return await _db
        .collection(collection)
        .doc(id)
        .get();
  }

  // ===========================
  // Flux d'un document
  // ===========================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
  fluxDocument({
    required String collection,
    required String id,
  }) {
    return _db
        .collection(collection)
        .doc(id)
        .snapshots();
  }

  // ===========================
  // Flux d'une collection
  // ===========================

  Stream<QuerySnapshot<Map<String, dynamic>>>
  fluxCollection({
    required String collection,
  }) {
    return _db.collection(collection).snapshots();
  }

  // ===========================
  // Flux d'une collection avec condition
  // ===========================

  Stream<QuerySnapshot<Map<String, dynamic>>> fluxCollectionCondition({
    required String collection,
    required String champ,
    required dynamic valeur,
  }) {
    return _db
        .collection(collection)
        .where(champ, isEqualTo: valeur)
        .snapshots();
  }

  // ===========================
  // Flux des transporteurs disponibles
  // ===========================

  Stream<QuerySnapshot<Map<String, dynamic>>> fluxTransporteursDisponibles() {
    return _db
        .collection("transporteurs")
        .where("disponible", isEqualTo: true)
        // Note: 'actif' n'est pas indexé par défaut avec disponible, si erreur Firestore d'index, enlever cette ligne et filtrer côté client.
        //.where("actif", isEqualTo: true)
        .snapshots();
  }

  // ===========================
  // Flux des courses (Client)
  // ===========================

  Stream<QuerySnapshot<Map<String, dynamic>>> fluxCoursesClient(String clientId) {
    return _db
        .collection("courses")
        .where("clientId", isEqualTo: clientId)
        .orderBy("dateCreation", descending: true)
        .snapshots();
  }

  // ===========================
  // Flux des courses (Transporteur)
  // ===========================

  Stream<QuerySnapshot<Map<String, dynamic>>> fluxCoursesTransporteur(String transporteurId) {
    return _db
        .collection("courses")
        .where("transporteurId", isEqualTo: transporteurId)
        .orderBy("dateCreation", descending: true)
        .snapshots();
  }

  // ===========================
  // Générer des données de test
  // ===========================

  Future<void> genererCoursesTest(String clientId) async {
    final batch = _db.batch();
    
    // 1. Course en cours
    final ref1 = _db.collection("courses").doc();
    batch.set(ref1, {
      "id": ref1.id,
      "clientId": clientId,
      "transporteurId": "transp_123",
      "codeSuivi": "CMR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
      "adresseDepart": "Douala, Akwa",
      "adresseArrivee": "Yaoundé, Bastos",
      "statut": "En cours",
      "typeVehicule": "Camionnette",
      "description": "Mobilier de bureau",
      "poidsKg": 120.5,
      "prixEstime": 45000.0,
      "dateCreation": FieldValue.serverTimestamp(),
      "dateDebut": FieldValue.serverTimestamp(),
      "dateFin": null,
    });

    // 2. Course livrée
    final ref2 = _db.collection("courses").doc();
    batch.set(ref2, {
      "id": ref2.id,
      "clientId": clientId,
      "transporteurId": "transp_456",
      "codeSuivi": "CMR-${(DateTime.now().millisecondsSinceEpoch - 100000).toString().substring(8)}",
      "adresseDepart": "Kribi, Port",
      "adresseArrivee": "Douala, Bonanjo",
      "statut": "Livré",
      "typeVehicule": "Camion lourd",
      "description": "Matériel de construction",
      "poidsKg": 850.0,
      "prixEstime": 120000.0,
      "dateCreation": FieldValue.serverTimestamp(),
      "dateDebut": FieldValue.serverTimestamp(),
      "dateFin": FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ===========================
  // Vérifier l'existence
  // ===========================

  Future<bool> documentExiste({
    required String collection,
    required String id,
  }) async {
    final doc = await _db
        .collection(collection)
        .doc(id)
        .get();

    return doc.exists;
  }
}