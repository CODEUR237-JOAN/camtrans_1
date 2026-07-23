import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/service_firestore.dart';
import '../../modeles/client.dart';
import '../../modeles/transporteur.dart';
import '../../modeles/course.dart';

// Providers pour lire toutes les données via Firebase (simulées ou réelles)

final adminClientsProvider = StreamProvider.autoDispose<List<Client>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  return firestore.fluxCollection(collection: 'clients').map((snapshot) {
    return snapshot.docs.map((doc) => Client.fromMap(doc.data())).toList();
  });
});

final adminTransporteursProvider = StreamProvider.autoDispose<List<Transporteur>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  return firestore.fluxCollection(collection: 'transporteurs').map((snapshot) {
    return snapshot.docs.map((doc) => Transporteur.fromMap(doc.data())).toList();
  });
});

final adminCoursesProvider = StreamProvider.autoDispose<List<Course>>((ref) {
  final firestore = ref.watch(serviceFirestoreProvider);
  return firestore.fluxCollection(collection: 'courses').map((snapshot) {
    return snapshot.docs.map((doc) => Course.fromMap(doc.data())).toList();
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

  // Calcul factice pour les revenus (ex: 2000 FCFA par course réussie)
  double revenus = 0;
  for (var course in courses) {
    if (course.statut == 'livree') {
      revenus += 2000;
    }
  }
  
  // S'il n'y a pas encore de données, on ajoute des données fictives pour l'UI
  if (revenus == 0) revenus = 1450000;
  int tc = clients.isEmpty ? 1240 : clients.length;
  int tt = transporteurs.isEmpty ? 315 : transporteurs.length;
  int tco = courses.isEmpty ? 5642 : courses.length;

  return AsyncValue.data(AdminStats(
    totalClients: tc,
    totalTransporteurs: tt,
    totalCourses: tco,
    revenusTotaux: revenus,
  ));
});

// Gère la navigation de l'administration
final adminMenuIndexProvider = StateProvider<int>((ref) => 0);
