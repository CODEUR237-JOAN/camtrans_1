import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/services/service_authentification.dart';
import 'package:update_camtrans/services/service_firestore.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';

final coursesClientProvider = StreamProvider.autoDispose<List<Course>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestoreService = ref.watch(serviceFirestoreProvider);
  
  final userId = authState.value?.uid;
  if (userId == null) {
    return Stream.value([]);
  }

  return firestoreService.fluxCoursesClient(userId).map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      // Ensure the document ID is passed to the model
      data['id'] = doc.id;
      return Course.fromMap(data);
    }).toList();
  });
});

final activeCourseClientProvider = Provider.autoDispose<Course?>((ref) {
  final coursesAsync = ref.watch(coursesClientProvider);
  return coursesAsync.maybeWhen(
    data: (courses) {
      try {
        // Un client a une course active si elle n'est ni terminée ni annulée
        return courses.firstWhere((c) => !StatutCourse.estTerminee(c.statut));
      } catch (_) {
        return null;
      }
    },
    orElse: () => null,
  );
});
