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
    // Utilisation de set avec merge: true au lieu de update
    // Cela évite l'erreur "No document to update" si le document n'existe pas encore
    await _db
        .collection(collection)
        .doc(id)
        .set(donnees, SetOptions(merge: true));
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

  /// Supprime les courses terminées ou annulées d'un utilisateur (client ou transporteur)
  Future<int> supprimerCoursesTerminees(String userId, {bool estClient = true}) async {
    final champ = estClient ? 'clientId' : 'transporteurId';
    final snapshot = await _db
        .collection('courses')
        .where(champ, isEqualTo: userId)
        .where('statut', whereIn: ['terminee', 'annulee'])
        .get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return snapshot.docs.length;
  }

  /// [ADMIN] Supprime TOUTES les courses terminées/annulées de la base (purge globale)
  Future<int> purgerHistoriqueGlobal() async {
    final snapshot = await _db
        .collection('courses')
        .where('statut', whereIn: ['terminee', 'annulee'])
        .get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return snapshot.docs.length;
  }

  /// [ADMIN] Supprime un compte utilisateur (son profil + toutes ses courses)
  Future<void> supprimerCompteUtilisateur(String userId, String role) async {
    final batch = _db.batch();
    // Supprimer le profil
    final collection = role == 'transporteur' ? 'transporteurs' : 'clients';
    batch.delete(_db.collection(collection).doc(userId));
    // Supprimer ses courses (en tant que client)
    final coursesClient = await _db.collection('courses').where('clientId', isEqualTo: userId).get();
    for (final doc in coursesClient.docs) {
      batch.delete(doc.reference);
    }
    // Supprimer ses courses (en tant que transporteur)
    final coursesTransp = await _db.collection('courses').where('transporteurId', isEqualTo: userId).get();
    for (final doc in coursesTransp.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
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
  // Messagerie
  // ===========================

  Stream<QuerySnapshot<Map<String, dynamic>>> fluxMessages(String conversationId) {
    return _db
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('dateEnvoi', descending: true)
        .snapshots();
  }

  Future<void> envoyerMessage(Map<String, dynamic> donneesMessage) async {
    final ref = _db.collection('messages').doc();
    donneesMessage['id'] = ref.id;
    await ref.set(donneesMessage);
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
  // Flux des courses proposees (Transporteur)
  // ===========================

  Stream<QuerySnapshot<Map<String, dynamic>>> fluxCoursesProposeesTransporteur(String transporteurId) {
    return _db
        .collection("courses")
        .where("statut", isEqualTo: "propose")
        .where("transporteurId", isEqualTo: transporteurId)
        .snapshots();
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