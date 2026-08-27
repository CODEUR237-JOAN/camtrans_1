import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/modeles/paiement.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';

// ID du transporteur actuellement connecté (lié à Firebase Auth)
final currentTransporteurIdProvider = Provider<String>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.uid ?? "";
});

// Transporteur connecté (objet complet)
final currentTransporteurProvider = StreamProvider.autoDispose<Transporteur?>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  final transporteurId = ref.watch(currentTransporteurIdProvider);

  if (transporteurId.isEmpty) return Stream.value(null);

  return firestore
      .fluxDocument(collection: 'transporteurs', id: transporteurId)
      .map((doc) {
    if (!doc.exists) return null;
    return Transporteur.fromMap(doc.data()!);
  });
});

// ==========================================
// 1. GESTION DES COURSES
// ==========================================



// Flux des courses assignées à ce transporteur
final fluxMesCoursesProvider =
    StreamProvider.autoDispose<List<Course>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  final transporteurId = ref.watch(currentTransporteurIdProvider);

  return firestore
      .fluxCollectionCondition(
        collection: 'courses',
        champ: 'transporteurId',
        valeur: transporteurId,
      )
      .map((snapshot) {
    var courses = snapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Course.fromMap(data);
        })
        .toList();
    // Tri par date de création décroissante
    courses.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    return courses;
  });
});

// Flux des courses en attente de transporteur (compatibles)
final fluxCoursesDisponiblesProvider = StreamProvider.autoDispose<List<Course>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  final transporteurAsync = ref.watch(currentTransporteurProvider);
  
  return transporteurAsync.when(
    data: (transporteur) {
      if (transporteur == null || !transporteur.disponible || !transporteur.documentsValides) {
        return Stream.value(<Course>[]);
      }
      
      return firestore
          .fluxCollectionCondition(
            collection: 'courses',
            champ: 'statut',
            valeur: StatutCourse.recherche,
          )
          .map((snapshot) {
        final courses = snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return Course.fromMap(data);
            })
            .where((c) {
               // Ignore si transporteurId est déjà défini (sécurité)
               if (c.transporteurId.isNotEmpty) return false;
               
               // Vérifier la compatibilité du véhicule
               if (c.typeVehicule.isNotEmpty && transporteur.typeVehicule.isNotEmpty) {
                 if (c.typeVehicule != transporteur.typeVehicule) return false;
               }
               
               return true;
            })
            .toList();
            
        courses.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
        return courses;
      });
    },
    loading: () => Stream.value(<Course>[]),
    error: (_, __) => Stream.value(<Course>[]),
  );
});

// Course active (celle en cours de livraison)
final activeCourseProvider = Provider.autoDispose<Course?>((ref) {
  final coursesAsync = ref.watch(fluxMesCoursesProvider);
  return coursesAsync.maybeWhen(
    data: (courses) {
      try {
        return courses.firstWhere(
            (c) => StatutCourse.estActive(c.statut)); //  helper unifié
      } catch (_) {
        return null;
      }
    },
    orElse: () => null,
  );
});

// Actions sur les courses
final transporteurActionsProvider = Provider<TransporteurActions>((ref) {
  return TransporteurActions(
    ref.read(serviceFirestoreProvider),
    ref.read(currentTransporteurIdProvider),
    
  );
});

class TransporteurActions {
  final ServiceFirestore _firestore;
  final String _transporteurId;
  // final Ref _ref;

  TransporteurActions(this._firestore, this._transporteurId, );


  /// Accepter une course (Dispatch automatique)
  Future<void> accepterCourse(String courseId) async {
    final courseDoc = await _firestore.lireDocument(
        collection: 'courses', id: courseId);
        
    if (!courseDoc.exists || courseDoc.data() == null) {
      throw Exception("Course introuvable.");
    }
    
    // On l'accepte et passe en route vers le départ
    final Map<String, dynamic> miseAJour = {
      'statut': StatutCourse.enRouteDepart,
      'dateDebut': DateTime.now().toIso8601String(),
    };

    await _firestore.modifierDocument(
      collection: 'courses',
      id: courseId,
      donnees: miseAJour,
    );
  }

  /// Refuser une course attribuée automatiquement (Cascade)
  Future<void> refuserCourse(String courseId) async {
    final courseDoc = await _firestore.lireDocument(
        collection: 'courses', id: courseId);
        
    if (!courseDoc.exists || courseDoc.data() == null) {
      throw Exception("Course introuvable.");
    }
    
    final courseData = courseDoc.data()!;
    final List<dynamic> declinesDyn = courseData['transporteursDeclines'] ?? [];
    final Set<String> declines = declinesDyn.map((e) => e.toString()).toSet();
    declines.add(_transporteurId);
    
    final double latDepart = courseData['latitudeDepart'] ?? 0.0;
    final double lngDepart = courseData['longitudeDepart'] ?? 0.0;
    final String typeVehicule = courseData['typeVehicule'] ?? '';

    // Trouver le prochain chauffeur dispo
    final transporteursSnapshot = await _firestore.transporteurs.get();
    
    String nextChauffeurId = '';
    String nextNom = '';
    String nextTel = '';
    double minDist = double.infinity;

    for (var doc in transporteursSnapshot.docs) {
      final t = doc.data();
      final id = doc.id;
      if (declines.contains(id)) continue;
      if (t['disponible'] != true) continue;
      if (t['documentsValides'] != true) continue;
      
      final tVehicule = t['typeVehicule'] ?? '';
      if (typeVehicule.isNotEmpty && tVehicule != typeVehicule && tVehicule != 'Tous') continue;
      
      final tLat = t['latitude'] ?? 0.0;
      final tLng = t['longitude'] ?? 0.0;
      
      double dist = double.infinity;
      if (latDepart != 0.0 && tLat != 0.0) {
          // Haversine exact (assuming we import math, or just use simple Pythagoras for small distances)
          final dLat = tLat - latDepart;
          final dLng = tLng - lngDepart;
          dist = dLat*dLat + dLng*dLng; // Distance au carré
      }
      
      if (dist < minDist) {
        minDist = dist;
        nextChauffeurId = id;
        nextNom = "${t['prenom']} ${t['nom']}";
        nextTel = t['telephone'] ?? '';
      }
    }

    final Map<String, dynamic> miseAJour = {
      'transporteursDeclines': FieldValue.arrayUnion([_transporteurId]),
    };

    if (nextChauffeurId.isNotEmpty) {
      // Assigner au prochain
      miseAJour['transporteurId'] = nextChauffeurId;
      miseAJour['nomTransporteur'] = nextNom;
      miseAJour['telephoneTransporteur'] = nextTel;
      miseAJour['statut'] = StatutCourse.attribue;
    } else {
      // Plus personne de disponible
      miseAJour['transporteurId'] = '';
      miseAJour['nomTransporteur'] = '';
      miseAJour['telephoneTransporteur'] = '';
      miseAJour['statut'] = StatutCourse.recherche;
    }

    await _firestore.modifierDocument(
      collection: 'courses',
      id: courseId,
      donnees: miseAJour,
    );
  }

  /// Change le statut d'une course en validant la transition
  Future<void> changerStatutCourse(String courseId, String nouveauStatut) async {
    // Lire le statut actuel pour valider la transition
    final courseDoc = await _firestore.lireDocument(
        collection: 'courses', id: courseId);
    if (!courseDoc.exists || courseDoc.data() == null) {
      throw Exception("Course introuvable.");
    }
    final statutActuel = courseDoc.data()!['statut'] as String? ?? '';

    if (!StatutCourse.peutTransitionnerVers(statutActuel, nouveauStatut)) {
      throw Exception(
          "Transition invalide : $statutActuel → $nouveauStatut");
    }

    final Map<String, dynamic> miseAJour = {'statut': nouveauStatut};

    // Enrichir la mise à jour selon le nouveau statut
    if (nouveauStatut == StatutCourse.arriveDestination) {
      miseAJour['dateFin'] = DateTime.now().toIso8601String();
    }
    if (nouveauStatut == StatutCourse.enRouteDepart) {
      miseAJour['dateDebut'] = DateTime.now().toIso8601String();
    }

    await _firestore.modifierDocument(
      collection: 'courses',
      id: courseId,
      donnees: miseAJour,
    );
  }

  /// Met à jour la disponibilité du transporteur dans Firestore
  Future<void> changerDisponibilite(bool estDisponible) async {
    if (_transporteurId.isEmpty) return;

    if (estDisponible) {
      final transporteurDoc = await _firestore.lireDocument(
          collection: 'transporteurs', id: _transporteurId);
      if (transporteurDoc.exists && transporteurDoc.data() != null) {
        if (transporteurDoc.data()!['documentsValides'] != true) {
          throw Exception(
              "Impossible de passer en ligne. Vos documents sont en cours de validation par l'administration.");
        }
      }
    }

    await _firestore.modifierDocument(
      collection: 'transporteurs',
      id: _transporteurId,
      donnees: {'disponible': estDisponible},
    );
  }
}

// ==========================================
// 2. GESTION DES REVENUS ET PAIEMENTS
// ==========================================

// Flux des paiements destinés à ce transporteur
final fluxMesRevenusProvider =
    StreamProvider.autoDispose<List<Paiement>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  final transporteurId = ref.watch(currentTransporteurIdProvider);

  return firestore
      .fluxCollectionCondition(
        collection: 'paiements',
        champ: 'transporteurId',
        valeur: transporteurId,
      )
      .map((snapshot) {
    var paiements = snapshot.docs
        .map((doc) => Paiement.fromMap(doc.data()))
        .toList();
    paiements.sort((a, b) => b.datePaiement.compareTo(a.datePaiement));
    return paiements;
  });
});

// Calculs statistiques basés sur le flux — valeurs corrigées
final statsRevenusProvider =
    Provider.autoDispose<Map<String, double>>((ref) {
  final paiementsAsync = ref.watch(fluxMesRevenusProvider);

  return paiementsAsync.maybeWhen(
    data: (paiements) {
      double total = 0;
      double ceMois = 0;
      double cetteSemaine = 0;
      double ceJour = 0; //  nouveau : revenus du jour

      final now = DateTime.now();
      final debutJour = DateTime(now.year, now.month, now.day);

      for (var p in paiements) {
        if (p.statut == StatutPaiement.succes) {
          total += p.montantNet;

          if (p.datePaiement.month == now.month &&
              p.datePaiement.year == now.year) {
            ceMois += p.montantNet;
          }

          if (now.difference(p.datePaiement).inDays <= 7) {
            cetteSemaine += p.montantNet;
          }

          //  Revenus du jour (depuis minuit)
          if (p.datePaiement.isAfter(debutJour)) {
            ceJour += p.montantNet;
          }
        }
      }
      return {
        'total': total,
        'ceMois': ceMois,
        'cetteSemaine': cetteSemaine,
        'ceJour': ceJour, //  valeur correcte pour le dashboard
      };
    },
    orElse: () =>
        {'total': 0, 'ceMois': 0, 'cetteSemaine': 0, 'ceJour': 0},
  );
});
