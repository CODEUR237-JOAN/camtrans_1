import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/modeles/client.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/modeles/paiement.dart';
import 'package:update_camtrans/modeles/parametres_app.dart';

// Providers pour lire toutes les données via Firebase (simulées ou réelles)

final adminClientsProvider = StreamProvider.autoDispose<List<Client>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  // ✅ AMÉLIORATION 2.1: Limité à 200 entrées pour éviter les surcharges mémoire
  return firestore.fluxCollection(collection: 'clients').map((snapshot) {
    return snapshot.docs.take(200).map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Client.fromMap(data);
    }).toList();
  });
});

final adminTransporteursProvider = StreamProvider.autoDispose<List<Transporteur>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  // ✅ AMÉLIORATION 2.1: Limité à 200 entrées
  return firestore.fluxCollection(collection: 'transporteurs').map((snapshot) {
    return snapshot.docs.take(200).map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Transporteur.fromMap(data);
    }).toList();
  });
});

final adminCoursesProvider = StreamProvider.autoDispose<List<Course>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  // ✅ AMÉLIORATION 2.1: Limité à 500 courses (les plus récentes)
  return firestore.fluxCollection(collection: 'courses').map((snapshot) {
    final courses = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Course.fromMap(data);
    }).toList();
    // Trier par date décroissante et prendre les 500 plus récentes
    courses.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    return courses.take(500).toList();
  });
});

// ===========================
// Abonnements des transporteurs
// ===========================

final adminAbonnementsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  return firestore.fluxCollection(collection: 'abonnements').map((snapshot) {
    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    // Trier par date décroissante
    list.sort((a, b) {
      final da = DateTime.tryParse(a['dateDebut'] ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['dateDebut'] ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });
    return list;
  });
});

// ===========================
// Paiements (tous)
// ===========================

final adminPaiementsProvider = StreamProvider.autoDispose<List<Paiement>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  return firestore.fluxCollection(collection: 'paiements').map((snapshot) {
    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Paiement.fromMap(data);
    }).toList();
    list.sort((a, b) => b.datePaiement.compareTo(a.datePaiement));
    return list;
  });
});

// ===========================
// Messages (toutes conversations)
// ===========================

final adminToutesConversationsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  return firestore.fluxCollection(collection: 'messages').map((snapshot) {
    // Grouper par conversationId
    final Map<String, List<Map<String, dynamic>>> groupes = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      final convId = data['conversationId'] as String? ?? 'inconnu';
      groupes.putIfAbsent(convId, () => []).add(data);
    }
    // Retourner un résumé de chaque conversation (dernier message)
    return groupes.entries.map((e) {
      final msgs = e.value;
      msgs.sort((a, b) {
        final da = a['dateEnvoi'];
        final db = b['dateEnvoi'];
        if (da == null || db == null) return 0;
        return db.toString().compareTo(da.toString());
      });
      return {
        'conversationId': e.key,
        'nombreMessages': msgs.length,
        'dernierMessage': msgs.first,
      };
    }).toList();
  });
});

// Provider paramétré : messages d'une conversation spécifique
final adminMessagesConversationProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, conversationId) {
  final firestore = ref.watch(serviceFirestoreProvider);
  return firestore.fluxMessages(conversationId).map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  });
});

// ===========================
// Paramètres de l'application
// ===========================

final adminParametresProvider = StreamProvider.autoDispose<ParametresApp>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  return firestore.fluxDocument(collection: 'parametres', id: 'globaux').map((doc) {
    if (doc.exists && doc.data() != null) {
      return ParametresApp.fromMap(doc.data()!);
    }
    return const ParametresApp();
  });
});

final adminUpdateParametresProvider = Provider.autoDispose((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  return (ParametresApp params) async {
    await firestore.ajouterDocument(
      collection: 'parametres',
      id: 'globaux',
      donnees: params.toMap(),
    );
  };
});

// Pour la page Vue d'ensemble : On calcule les stats globales
class AdminStats {
  final int totalClients;
  final int totalTransporteurs;
  final int totalCourses;
  final double revenusTotaux;

  final List<double> clientsHistory;
  final List<double> transporteursHistory;
  final List<double> coursesHistory;
  final List<double> revenusHistory;

  final double trendRevenus;
  final double trendClients;
  final double trendTransporteurs;
  final double trendCourses;

  AdminStats({
    required this.totalClients,
    required this.totalTransporteurs,
    required this.totalCourses,
    required this.revenusTotaux,
    required this.clientsHistory,
    required this.transporteursHistory,
    required this.coursesHistory,
    required this.revenusHistory,
    required this.trendRevenus,
    required this.trendClients,
    required this.trendTransporteurs,
    required this.trendCourses,
  });
}

final adminStatsProvider = Provider.autoDispose<AsyncValue<AdminStats>>((ref) {
  final clientsAsync = ref.watch(adminClientsProvider);
  final transporteursAsync = ref.watch(adminTransporteursProvider);
  final coursesAsync = ref.watch(adminCoursesProvider);

  if (clientsAsync is AsyncLoading || transporteursAsync is AsyncLoading || coursesAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  if (clientsAsync is AsyncError) return AsyncValue.error(clientsAsync.error!, clientsAsync.stackTrace!);
  if (transporteursAsync is AsyncError) return AsyncValue.error(transporteursAsync.error!, transporteursAsync.stackTrace!);
  if (coursesAsync is AsyncError) return AsyncValue.error(coursesAsync.error!, coursesAsync.stackTrace!);

  final clients = clientsAsync.value ?? [];
  final transporteurs = transporteursAsync.value ?? [];
  final courses = coursesAsync.value ?? [];

  final now = DateTime.now().toLocal();
  final debutAujourdhuiLocal = DateTime(now.year, now.month, now.day);
  
  // Historiques sur 7 jours
  List<double> revHist = List.filled(7, 0.0);
  List<double> cliHist = List.filled(7, 0.0);
  List<double> transHist = List.filled(7, 0.0);
  List<double> coursHist = List.filled(7, 0.0);

  // Clients
  for (var c in clients) {
    final diff = debutAujourdhuiLocal.difference(c.dateCreation.toLocal()).inDays;
    if (diff >= 0 && diff < 7) cliHist[6 - diff] += 1;
  }
  // Transporteurs
  for (var t in transporteurs) {
    final diff = debutAujourdhuiLocal.difference(t.dateCreation.toLocal()).inDays;
    if (diff >= 0 && diff < 7) transHist[6 - diff] += 1;
  }
  // Courses et Revenus
  double revenus = 0;
  for (var course in courses) {
    final diff = debutAujourdhuiLocal.difference(course.dateCreation.toLocal()).inDays;
    
    if (diff >= 0 && diff < 7) coursHist[6 - diff] += 1;

    if (StatutCourse.estTerminee(course.statut) && course.statut != StatutCourse.annulee) {
      double p = course.prixFinal > 0 ? course.prixFinal : course.prixEstime;
      revenus += p;
      if (diff >= 0 && diff < 7) revHist[6 - diff] += p;
    }
  }

  // Calcul du trend: (aujourd'hui - hier) / hier. Simplifié pour affichage.
  double calcTrend(List<double> h) {
    if (h[5] == 0) return h[6] > 0 ? 100.0 : 0.0;
    return ((h[6] - h[5]) / h[5]) * 100.0;
  }

  // Si on veut des courbes "cumulatives" plutôt que par jour, on peut faire :
  // Mais par jour c'est mieux pour des sparklines !
  
  // ✅ CORRECTION 1.5: Suppression des données fictives injectées quand tout = 0
  // Ces données étaient trompeuses pour l'admin (il voyait de faux graphiques).
  // Désormais, si aucune donnée réelle, les historiques restent à 0 (honnête).
  // Cela permet à l'admin de voir le vrai état du système au démarrage.

  return AsyncValue.data(AdminStats(
    totalClients: clients.length,
    totalTransporteurs: transporteurs.length,
    totalCourses: courses.length,
    revenusTotaux: revenus,
    clientsHistory: cliHist,
    transporteursHistory: transHist,
    coursesHistory: coursHist,
    revenusHistory: revHist,
    trendRevenus: calcTrend(revHist),
    trendClients: calcTrend(cliHist),
    trendTransporteurs: calcTrend(transHist),
    trendCourses: calcTrend(coursHist),
  ));
});

// Répartition des courses par statut
final adminCourseDistributionProvider = Provider.autoDispose<AsyncValue<Map<String, int>>>((ref) {
  final coursesAsync = ref.watch(adminCoursesProvider);
  return coursesAsync.whenData((courses) {
    final Map<String, int> distribution = {};
    for (var c in courses) {
      String raw = c.statut.toLowerCase();
      String statutClean;
      
      // Normalisation des anciens statuts ou variations
      if (raw.contains('livr') || raw.contains('termin')) {
        statutClean = StatutCourse.terminee;
      } else if (raw.contains('accept') || raw.contains('attribu')) statutClean = StatutCourse.attribue;
      else if (raw.contains('cour') || raw.contains('transit') || raw.contains('rout')) statutClean = StatutCourse.enTransit;
      else if (raw.contains('attent') || raw.contains('recherch')) statutClean = StatutCourse.recherche;
      else if (raw.contains('annul')) statutClean = StatutCourse.annulee;
      else statutClean = c.statut;

      String label = StatutCourse.libelle(statutClean);
      if (label == statutClean) {
        label = label.isNotEmpty ? label[0].toUpperCase() + label.substring(1) : label;
      }
      
      distribution[label] = (distribution[label] ?? 0) + 1;
    }
    return distribution;
  });
});

// Activités très récentes (5 dernières)
final adminRecentActivitiesProvider = Provider.autoDispose<AsyncValue<List<Course>>>((ref) {
  final coursesAsync = ref.watch(adminCoursesProvider);
  return coursesAsync.whenData((courses) {
    final sorted = List<Course>.from(courses);
    sorted.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    return sorted.take(5).toList();
  });
});

// Compteur de modération en attente
final adminPendingApprovalsCountProvider = Provider.autoDispose<AsyncValue<int>>((ref) {
  final transporteursAsync = ref.watch(adminTransporteursProvider);
  return transporteursAsync.whenData((list) => list.where((t) => !t.documentsValides).length);
});

// Provider pour la vue de la carte (Standard ou Satellite)
final isSatelliteViewProvider = StateProvider<bool>((ref) => false);
const String urlCarteStandard = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String urlCarteSatellite = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

// Index du menu sélectionné dans la sidebar
final adminMenuIndexProvider = StateProvider<int>((ref) => 0);

// Revenus hebdomadaires (pour le graphique)
final adminWeeklyRevenuesProvider = Provider.autoDispose<AsyncValue<List<double>>>((ref) {
  final coursesAsync = ref.watch(adminCoursesProvider);

  return coursesAsync.maybeWhen(
    data: (courses) {
      final List<double> weeklyData = List.filled(7, 0.0);
      // Fuseau horaire du Cameroun : UTC+1
      final now = DateTime.now().toLocal();
      final debutAujourdhuiLocal = DateTime(now.year, now.month, now.day);

      for (var course in courses) {
        if (StatutCourse.estTerminee(course.statut) && course.statut != StatutCourse.annulee) {
          // Convertir la date de la course en heure locale
          final dateLocale = course.dateCreation.toLocal();
          final debutJourCourse = DateTime(dateLocale.year, dateLocale.month, dateLocale.day);
          final diff = debutAujourdhuiLocal.difference(debutJourCourse).inDays;
          if (diff >= 0 && diff < 7) {
            // Index 6 = aujourd'hui, 0 = il y a 6 jours
            final index = 6 - diff;
            weeklyData[index] += course.prixFinal > 0 ? course.prixFinal : course.prixEstime;
          }
        }
      }
      return AsyncValue.data(weeklyData);
    },
    orElse: () => const AsyncValue.loading(),
  );
});
