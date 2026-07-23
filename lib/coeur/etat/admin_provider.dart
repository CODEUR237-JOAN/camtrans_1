import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/service_firestore.dart';
import '../../modeles/client.dart';
import '../../modeles/transporteur.dart';
import '../../modeles/course.dart';

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
    if (course.statut == 'Livré' || course.statut == 'livree') {
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
        if (course.statut == 'Livré' || course.statut == 'livree') {
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
