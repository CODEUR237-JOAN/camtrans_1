import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/modeles/client.dart';
import 'package:update_camtrans/modeles/transporteur.dart';
import 'package:update_camtrans/modeles/course.dart';

// Providers pour lire toutes les données via Firebase (simulées ou réelles)

final adminClientsProvider = StreamProvider.autoDispose<List<Client>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  return firestore.fluxCollection(collection: 'clients').map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Client.fromMap(data);
    }).toList();
  });
});

final adminTransporteursProvider = StreamProvider.autoDispose<List<Transporteur>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  return firestore.fluxCollection(collection: 'transporteurs').map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Transporteur.fromMap(data);
    }).toList();
  });
});

final adminCoursesProvider = StreamProvider.autoDispose<List<Course>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  return firestore.fluxCollection(collection: 'courses').map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Course.fromMap(data);
    }).toList();
  });
});

// Pour la page Vue d'ensemble : On calcule les stats globales
class AdminStats {
  final int totalClients;
  final int totalTransporteurs;
  final int totalCourses;
  final double revenusTotaux;

  AdminStats({
    required this.totalClients,
    required this.totalTransporteurs,
    required this.totalCourses,
    required this.revenusTotaux,
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

  // Calcul des revenus réels à partir des courses livrées
  double revenus = 0;
  for (var course in courses) {
    if (StatutCourse.estTerminee(course.statut) && course.statut != StatutCourse.annulee) {
      revenus += course.prixFinal > 0 ? course.prixFinal : course.prixEstime;
    }
  }

  return AsyncValue.data(AdminStats(
    totalClients: clients.length,
    totalTransporteurs: transporteurs.length,
    totalCourses: courses.length,
    revenusTotaux: revenus,
  ));
});

// Répartition des courses par statut
final adminCourseDistributionProvider = Provider.autoDispose<AsyncValue<Map<String, int>>>((ref) {
  final coursesAsync = ref.watch(adminCoursesProvider);
  return coursesAsync.whenData((courses) {
    final Map<String, int> distribution = {};
    for (var c in courses) {
      distribution[c.statut] = (distribution[c.statut] ?? 0) + 1;
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

// Gère la navigation de l'administration
final adminMenuIndexProvider = StateProvider<int>((ref) => 0);

// Revenus hebdomadaires (pour le graphique)
final adminWeeklyRevenuesProvider = Provider.autoDispose<AsyncValue<List<double>>>((ref) {
  final coursesAsync = ref.watch(adminCoursesProvider);

  return coursesAsync.maybeWhen(
    data: (courses) {
      final List<double> weeklyData = List.filled(7, 0.0);
      final now = DateTime.now();

      for (var course in courses) {
        if (StatutCourse.estTerminee(course.statut) && course.statut != StatutCourse.annulee) {
          final diff = now.difference(course.dateCreation).inDays;
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
