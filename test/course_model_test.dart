import 'package:flutter_test/flutter_test.dart';
import 'package:update_camtrans/modeles/course.dart';
import 'package:update_camtrans/modeles/paiement.dart';
import 'package:update_camtrans/coeur/constantes/statuts.dart';

// ============================================================
// Fabrique de données de test — évite la répétition dans chaque test
// ============================================================

Course _courseSample() => Course(
      id: 'CT-2024-001',
      clientId: 'client-abc',
      transporteurId: 'transpo-xyz',
      nomClient: 'Jean Dupont',
      nomTransporteur: 'Kamer Express',
      telephoneClient: '699123456',
      telephoneTransporteur: '677654321',
      adresseDepart: 'Rue de la Joie, Yaoundé',
      adresseArrivee: 'Boulevard du Peuple, Douala',
      latitudeDepart: 3.848,
      longitudeDepart: 11.502,
      latitudeArrivee: 4.061,
      longitudeArrivee: 9.778,
      distanceKm: 245.0,
      volumeM3: 12.5,
      poidsKg: 800.0,
      typeVehicule: 'Camion 5T',
      typeMarchandise: 'Mobilier',
      prixEstime: 75000.0,
      prixFinal: 80000.0,
      modePaiement: 'MTN Mobile Money',
      paiementEffectue: false,
      statut: StatutCourse.recherche,
      description: 'Déménagement complet appartement 3 pièces',
      photos: ['photo1.jpg', 'photo2.jpg'],
      dateCreation: DateTime(2024, 1, 15, 10, 0),
      fragile: true,
      aideChargement: true,
      aideDechargement: false,
      codeSuivi: 'CT001',
      noteClient: 0.0,
      noteTransporteur: 0.0,
      commentaireClient: '',
      commentaireTransporteur: '',
      scoreIA: 0.92,
      vehiculeRecommandeIA: 'Camion 5T',
      volumeEstimeIA: 13.0,
      conseilIA: 'Prévoir des couvertures protectrices',
      etaMinutes: 0,
    );

Paiement _paiementSample() => Paiement(
      id: 'PAY-2024-001',
      courseId: 'CT-2024-001',
      clientId: 'client-abc',
      transporteurId: 'transpo-xyz',
      montant: 80000.0,
      devise: 'FCFA',
      methodePaiement: 'MTN Mobile Money',
      numeroTransaction: 'MTN-TXN-987654',
      statut: StatutPaiement.enAttente,
      datePaiement: DateTime(2024, 1, 15, 10, 30),
      paiementConfirme: false,
      reference: 'REF-001',
      operateur: 'MTN',
      telephonePayeur: '699123456',
      commentaire: '',
      fraisTransaction: 800.0,
      montantNet: 79200.0,
      remboursementEffectue: false,
      motifRemboursement: '',
      facturePdf: '',
    );

// ============================================================
// TESTS
// ============================================================

void main() {
  group('Tests de sérialisation — Modèle Course', () {
    test('1. toMap() → fromMap() conserve toutes les valeurs (aller-retour)', () {
      final original = _courseSample();
      final map = original.toMap();
      final reconstruit = Course.fromMap(map);

      // Identité
      expect(reconstruit.id, equals(original.id));
      expect(reconstruit.clientId, equals(original.clientId));
      expect(reconstruit.adresseDepart, equals(original.adresseDepart));
      expect(reconstruit.adresseArrivee, equals(original.adresseArrivee));
      expect(reconstruit.statut, equals(original.statut));

      // Numériques & booléens
      expect(reconstruit.distanceKm, equals(original.distanceKm));
      expect(reconstruit.volumeM3, equals(original.volumeM3));
      expect(reconstruit.prixEstime, equals(original.prixEstime));
      expect(reconstruit.fragile, equals(original.fragile));
      expect(reconstruit.fondsDebloques, equals(original.fondsDebloques));
      expect(reconstruit.etaMinutes, equals(original.etaMinutes));

      // Listes
      expect(reconstruit.photos, equals(original.photos));
      expect(reconstruit.candidats, equals(original.candidats));

      // IA
      expect(reconstruit.scoreIA, equals(original.scoreIA));
      expect(reconstruit.vehiculeRecommandeIA, equals(original.vehiculeRecommandeIA));

      // Dates
      expect(reconstruit.dateCreation, equals(original.dateCreation));
      expect(reconstruit.dateModification, isNull);
    });

    test('2. copyWith() modifie uniquement les champs spécifiés', () {
      final original = _courseSample();
      final modifie = original.copyWith(
        statut: StatutCourse.attribue,
        etaMinutes: 45,
        dateModification: DateTime(2024, 1, 15, 11, 0),
      );

      // Champs modifiés
      expect(modifie.statut, equals(StatutCourse.attribue));
      expect(modifie.etaMinutes, equals(45));
      expect(modifie.dateModification, equals(DateTime(2024, 1, 15, 11, 0)));

      // Champs non touchés (immuabilité partielle)
      expect(modifie.id, equals(original.id));
      expect(modifie.distanceKm, equals(original.distanceKm));
      expect(modifie.nomClient, equals(original.nomClient));
      expect(modifie.scoreIA, equals(original.scoreIA));
    });

    test('3. Sérialisation des nouveaux champs (dateModification & etaMinutes)', () {
      final now = DateTime(2024, 6, 1, 12, 0);
      final course = _courseSample().copyWith(
        etaMinutes: 120,
        dateModification: now,
      );

      final map = course.toMap();
      expect(map['etaMinutes'], equals(120));
      expect(map['dateModification'], equals(now.toIso8601String()));

      // Retour depuis la map
      final reconstruit = Course.fromMap(map);
      expect(reconstruit.etaMinutes, equals(120));
      expect(reconstruit.dateModification, equals(now));
    });
  });

  group('Tests de sérialisation — Modèle Paiement', () {
    test('4. toMap() → fromMap() conserve toutes les valeurs', () {
      final original = _paiementSample();
      final reconstruit = Paiement.fromMap(original.toMap());

      expect(reconstruit.id, equals(original.id));
      expect(reconstruit.montant, equals(original.montant));
      expect(reconstruit.fraisTransaction, equals(original.fraisTransaction));
      expect(reconstruit.montantNet, equals(original.montantNet));
      expect(reconstruit.statut, equals(original.statut));
      expect(reconstruit.paiementConfirme, equals(original.paiementConfirme));
      expect(reconstruit.remboursementEffectue, equals(original.remboursementEffectue));
      expect(reconstruit.dateRemboursement, isNull);
    });

    test('5. copyWith() sur Paiement modifie uniquement le statut (succès MTN)', () {
      final original = _paiementSample();
      final confirme = original.copyWith(
        statut: StatutPaiement.succes,
        paiementConfirme: true,
        numeroTransaction: 'MTN-TXN-CONFIRMED-001',
      );

      expect(confirme.statut, equals(StatutPaiement.succes));
      expect(confirme.paiementConfirme, isTrue);
      expect(confirme.numeroTransaction, equals('MTN-TXN-CONFIRMED-001'));

      // Non-touchés
      expect(confirme.id, equals(original.id));
      expect(confirme.montant, equals(original.montant));
      expect(confirme.courseId, equals(original.courseId));
    });

    test('6. Scénario de remboursement complet', () {
      final dateRbt = DateTime(2024, 1, 16, 9, 0);
      final rembourse = _paiementSample().copyWith(
        statut: StatutPaiement.rembourse,
        remboursementEffectue: true,
        dateRemboursement: dateRbt,
        motifRemboursement: 'Course annulée par le client',
      );

      expect(rembourse.statut, equals(StatutPaiement.rembourse));
      expect(rembourse.remboursementEffectue, isTrue);
      expect(rembourse.dateRemboursement, equals(dateRbt));
      expect(rembourse.motifRemboursement, equals('Course annulée par le client'));

      // Sérialiser puis désérialiser le remboursement
      final map = rembourse.toMap();
      final reconstruit = Paiement.fromMap(map);
      expect(reconstruit.remboursementEffectue, isTrue);
      expect(reconstruit.dateRemboursement, equals(dateRbt));
    });
  });
}
