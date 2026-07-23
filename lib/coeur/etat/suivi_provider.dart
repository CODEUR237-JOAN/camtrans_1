import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/service_firestore.dart';
import '../../modeles/course.dart';
import '../../modeles/transporteur.dart';

// État combiné du suivi
class EtatSuivi {
  final bool chargement;
  final Course? course;
  final Transporteur? transporteur;
  final String? erreur;

  EtatSuivi({
    this.chargement = true,
    this.course,
    this.transporteur,
    this.erreur,
  });

  EtatSuivi copierAvec({
    bool? chargement,
    Course? course,
    Transporteur? transporteur,
    String? erreur,
  }) {
    return EtatSuivi(
      chargement: chargement ?? this.chargement,
      course: course ?? this.course,
      transporteur: transporteur ?? this.transporteur,
      erreur: erreur ?? this.erreur,
    );
  }
}

// Provider paramétré par l'ID de la course
final suiviProvider = StateNotifierProvider.family<SuiviNotifier, EtatSuivi, String>((ref, courseId) {
  return SuiviNotifier(ref.read(serviceFirestoreProvider), courseId);
});

class SuiviNotifier extends StateNotifier<EtatSuivi> {
  final ServiceFirestore _firestore;
  StreamSubscription? _courseSubscription;
  StreamSubscription? _transporteurSubscription;

  SuiviNotifier(this._firestore, String courseId) : super(EtatSuivi()) {
    _initialiserEcoute(courseId);
  }

  void _initialiserEcoute(String courseId) {
    _courseSubscription = _firestore.fluxDocument(collection: 'courses', id: courseId).listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final course = Course.fromMap(snapshot.data()!);
        
        state = state.copierAvec(course: course, chargement: false);

        // Si le transporteur est défini, on écoute sa position
        if (course.transporteurId.isNotEmpty && _transporteurSubscription == null) {
          _ecouterTransporteur(course.transporteurId);
        }
      } else {
        state = state.copierAvec(erreur: "Course introuvable", chargement: false);
      }
    }, onError: (e) {
      state = state.copierAvec(erreur: e.toString(), chargement: false);
    });
  }

  void _ecouterTransporteur(String transporteurId) {
    _transporteurSubscription = _firestore.fluxDocument(collection: 'transporteurs', id: transporteurId).listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final transporteur = Transporteur.fromMap(snapshot.data()!);
        state = state.copierAvec(transporteur: transporteur);
      }
    });
  }

  @override
  void dispose() {
    _courseSubscription?.cancel();
    _transporteurSubscription?.cancel();
    super.dispose();
  }
}
