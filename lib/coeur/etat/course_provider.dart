import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../modeles/course.dart';
import '../../services/service_authentification.dart';
import '../../services/service_firestore.dart';

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
