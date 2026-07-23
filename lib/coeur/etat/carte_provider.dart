import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../services/service_gps.dart';

// État de la carte
class EtatCarte {
  final LatLng? positionActuelle;
  final bool chargement;
  final bool erreurGps;
  final bool horsLigne;

  EtatCarte({
    this.positionActuelle,
    this.chargement = true,
    this.erreurGps = false,
    this.horsLigne = false,
  });

  EtatCarte copierAvec({
    LatLng? positionActuelle,
    bool? chargement,
    bool? erreurGps,
    bool? horsLigne,
  }) {
    return EtatCarte(
      positionActuelle: positionActuelle ?? this.positionActuelle,
      chargement: chargement ?? this.chargement,
      erreurGps: erreurGps ?? this.erreurGps,
      horsLigne: horsLigne ?? this.horsLigne,
    );
  }
}

class CarteNotifier extends StateNotifier<EtatCarte> {
  final ServiceGps _serviceGps;
  StreamSubscription? _subscriptionReseau;
  StreamSubscription? _subscriptionPosition;

  CarteNotifier(this._serviceGps) : super(EtatCarte()) {
    _initialiser();
  }

  Future<void> _initialiser() async {
    // Vérifier la connectivité
    final connectivityResult = await (Connectivity().checkConnectivity());
    _verifierConnectivite(connectivityResult);

    _subscriptionReseau = Connectivity().onConnectivityChanged.listen(_verifierConnectivite);

    await actualiserPosition();
  }

  void _verifierConnectivite(List<ConnectivityResult> resultats) {
    bool horsLigne = resultats.isEmpty || resultats.contains(ConnectivityResult.none);
    state = state.copierAvec(horsLigne: horsLigne);
  }

  Future<void> actualiserPosition() async {
    state = state.copierAvec(chargement: true, erreurGps: false);

    final position = await _serviceGps.obtenirPositionActuelle();

    if (position != null) {
      state = state.copierAvec(
        positionActuelle: LatLng(position.latitude, position.longitude),
        chargement: false,
        erreurGps: false,
      );
    } else {
      state = state.copierAvec(
        chargement: false,
        erreurGps: true,
      );
    }
  }

  @override
  void dispose() {
    _subscriptionReseau?.cancel();
    _subscriptionPosition?.cancel();
    super.dispose();
  }
}

final carteProvider = StateNotifierProvider<CarteNotifier, EtatCarte>((ref) {
  final serviceGps = ref.read(serviceGpsProvider);
  return CarteNotifier(serviceGps);
});
