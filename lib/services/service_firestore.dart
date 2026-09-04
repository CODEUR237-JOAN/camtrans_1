import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final serviceFirestoreProvider = Provider<ServiceFirestore>((ref) {
  return ServiceFirestore();
});

class ServiceFirestore {
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  // ===========================
  // Accès aux Collections Principales
  // Ces getters fournissent un accès direct aux tables de la base de données Firestore.
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
  // Opérations d'Écriture : Ajout
  // ===========================

  /// Crée un nouveau document dans la collection spécifiée.
  /// Écrase les données si le document existe déjà avec le même identifiant.

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
  // Opérations d'Écriture : Modification
  // ===========================

  /// Met à jour les champs spécifiques d'un document existant.
  /// Utilise `SetOptions(merge: true)` pour garantir que si le document 
  /// n'existe pas encore, il sera créé sans provoquer d'erreur technique.
  Future<void> modifierDocument({
    required String collection,
    required String id,
    required Map<String, dynamic> donnees,
  }) async {
    await _db
        .collection(collection)
        .doc(id)
        .set(donnees, SetOptions(merge: true));
  }

  // ===========================
  // Opérations d'Écriture : Suppression
  // ===========================

  /// Supprime définitivement un document de la base de données.

  Future<void> supprimerDocument({
    required String collection,
    required String id,
  }) async {
    await _db
        .collection(collection)
        .doc(id)
        .delete();
  }

  /// Masque les courses terminées du CLIENT dans son historique.
  /// Chaque rôle a son propre flag d'archivage — l'admin voit toujours tout.
  Future<int> supprimerCoursesTerminees(String userId, {bool estClient = true}) async {
    if (!estClient) {
      return archiverCoursesTerminees(userId);
    }
    final snapshot = await _db
        .collection('courses')
        .where('clientId', isEqualTo: userId)
        .where('statut', whereIn: ['terminee', 'annulee'])
        .get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      // Archivage logique : le client masque sa vue, l'admin et le transporteur
      // conservent accès à la même course via leurs propres flags.
      if (doc.data()['archivePourClient'] != true) {
        batch.update(doc.reference, {'archivePourClient': true});
      }
    }
    await batch.commit();
    return snapshot.docs.length;
  }

  /// Archive logiquement les courses du transporteur (flag Firestore).
  /// Le transporteur ne peut pas supprimer les courses, mais peut les masquer.
  Future<int> archiverCoursesTerminees(String userId) async {
    final snapshot = await _db
        .collection('courses')
        .where('transporteurId', isEqualTo: userId)
        .where('statut', whereIn: ['terminee', 'annulee'])
        .get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'archivePourTransporteur': true});
    }
    await batch.commit();
    return snapshot.docs.length;
  }

  /// [ADMINISTRATION] Purge globale de la base de données.
  /// Supprime toutes les courses inactives (terminées ou annulées) de tous les utilisateurs
  /// pour libérer de l'espace de stockage. Action irréversible.
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

  /// [ADMINISTRATION] Suppression d'un compte utilisateur.
  /// Efface le profil de l'utilisateur ainsi que tout son historique de courses associé.
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
  // Opérations de Lecture Simple
  // ===========================

  /// Récupère les informations d'un document spécifique de manière asynchrone (une seule fois).

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
  // Écoute en Temps Réel (Streaming) : Document unique
  // ===========================

  /// Permet d'écouter les modifications d'un document en temps réel.
  /// L'interface utilisateur se mettra à jour automatiquement dès que les données changent dans Firestore.

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
  // Écoute en Temps Réel (Streaming) : Collection entière
  // ===========================

  /// Permet d'écouter les modifications sur l'ensemble d'une collection.

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