import 'package:flutter_riverpod/flutter_riverpod.dart';

// =====================================================================
// SERVICE DE DONNÉES VÉHICULES (mocké)
//
// Fournit la liste des marques et, pour chaque marque, ses modèles
// courants (orientés marché camerounais : Douala / Yaoundé). Sert de
// source aux listes déroulantes « cascade » Marque → Modèle du service
// de remorquage.
//
// Hors-ligne, sans coût, sans clé API. Peut être remplacé plus tard par
// une vraie API sans changer l'UI (même interface publique).
// =====================================================================
class ServiceDonneesVehicules {
  // Marque -> modèles. L'ordre des marques reflète la popularité locale.
  static const Map<String, List<String>> _marquesEtModeles = {
    'Toyota': [
      'Corolla',
      'Yaris',
      'Camry',
      'Avensis',
      'RAV4',
      'Prado',
      'Land Cruiser',
      'Hilux',
      'Hiace',
      'Fortuner',
      'Carina',
      'Dyna',
    ],
    'Mercedes': [
      'Classe A',
      'Classe C',
      'Classe E',
      'Classe S',
      'GLA',
      'GLC',
      'GLE',
      'Sprinter',
      'Vito',
      'Actros',
      'Atego',
    ],
    'Hyundai': [
      'i10',
      'i20',
      'Accent',
      'Elantra',
      'Sonata',
      'Tucson',
      'Santa Fe',
      'Creta',
      'H1',
      'HD65',
      'HD72',
    ],
    'Kia': [
      'Picanto',
      'Rio',
      'Cerato',
      'Optima',
      'Sportage',
      'Sorento',
      'Carnival',
      'K2500',
      'K2700',
    ],
    'Nissan': [
      'Micra',
      'Sunny',
      'Almera',
      'Sentra',
      'Qashqai',
      'X-Trail',
      'Patrol',
      'Navara',
      'Pathfinder',
      'Cabstar',
    ],
    'Peugeot': [
      '206',
      '207',
      '208',
      '301',
      '307',
      '308',
      '406',
      '407',
      '508',
      '2008',
      '3008',
      'Partner',
      'Boxer',
    ],
    'Renault': [
      'Clio',
      'Symbol',
      'Mégane',
      'Logan',
      'Sandero',
      'Duster',
      'Kangoo',
      'Master',
      'Trafic',
    ],
    'Ford': [
      'Fiesta',
      'Focus',
      'Fusion',
      'Escape',
      'Ranger',
      'Everest',
      'Transit',
      'F-150',
    ],
    'Volkswagen': [
      'Polo',
      'Golf',
      'Passat',
      'Jetta',
      'Tiguan',
      'Touareg',
      'Caddy',
      'Crafter',
      'Transporter',
    ],
    'Honda': [
      'Jazz',
      'Civic',
      'Accord',
      'City',
      'CR-V',
      'HR-V',
      'Pilot',
    ],
    'Mitsubishi': [
      'Lancer',
      'Mirage',
      'ASX',
      'Outlander',
      'Pajero',
      'L200',
      'Canter',
      'Fuso',
    ],
    'Suzuki': [
      'Alto',
      'Swift',
      'Baleno',
      'Vitara',
      'Grand Vitara',
      'Jimny',
      'Ertiga',
      'Carry',
    ],
    'Isuzu': [
      'D-Max',
      'MU-X',
      'NPR',
      'NQR',
      'FVR',
      'FRR',
    ],
    'Hino': [
      '300',
      '500',
      '700',
      'Dutro',
      'Ranger',
    ],
    'Man': [
      'TGS',
      'TGX',
      'TGM',
      'TGL',
      'TGE',
    ],
    'Iveco': [
      'Daily',
      'Eurocargo',
      'Stralis',
      'Trakker',
    ],
    'Fuso': [
      'Canter',
      'Fighter',
      'Super Great',
    ],
    'JAC': [
      'J3',
      'J5',
      'S3',
      'S5',
      'T6',
      'T8',
      'N-Series',
    ],
    'Foton': [
      'Tunland',
      'Aumark',
      'Ollin',
      'View',
    ],
    'Tata': [
      'Indica',
      'Indigo',
      'Xenon',
      'Ace',
      'LPT',
    ],
    'Land Rover': [
      'Defender',
      'Discovery',
      'Range Rover',
      'Range Rover Sport',
      'Freelander',
    ],
    'BMW': [
      'Série 1',
      'Série 3',
      'Série 5',
      'Série 7',
      'X1',
      'X3',
      'X5',
      'X6',
    ],
    'Audi': [
      'A3',
      'A4',
      'A6',
      'A8',
      'Q3',
      'Q5',
      'Q7',
    ],
    'Citroën': [
      'C3',
      'C4',
      'C5',
      'Berlingo',
      'Jumper',
      'Jumpy',
    ],
    'Opel': [
      'Corsa',
      'Astra',
      'Insignia',
      'Mokka',
      'Vivaro',
      'Movano',
    ],
    'Mazda': [
      'Mazda2',
      'Mazda3',
      'Mazda6',
      'CX-3',
      'CX-5',
      'BT-50',
    ],
    'Volvo': [
      'FH',
      'FM',
      'FMX',
      'FL',
      'XC60',
      'XC90',
    ],
    'Scania': [
      'P-Series',
      'G-Series',
      'R-Series',
      'S-Series',
    ],
    'DAF': [
      'LF',
      'CF',
      'XF',
    ],
    // « Autre » : saisie libre du modèle (aucune liste imposée).
    'Autre': [],
  };

  /// Toutes les marques disponibles (dans l'ordre de popularité locale).
  List<String> get marques => _marquesEtModeles.keys.toList();

  /// Les modèles d'une marque donnée (liste vide si marque inconnue).
  List<String> modelesPour(String marque) =>
      _marquesEtModeles[marque] ?? const [];

  /// Vrai si la marque autorise une saisie libre du modèle
  /// (« Autre », ou marque sans liste de modèles).
  bool saisieLibreModele(String marque) => modelesPour(marque).isEmpty;

  /// Filtre les modèles d'une marque selon la saisie (insensible à la casse).
  List<String> rechercherModeles(String marque, String saisie) {
    final modeles = modelesPour(marque);
    final q = saisie.trim().toLowerCase();
    if (q.isEmpty) return modeles;
    return modeles.where((m) => m.toLowerCase().contains(q)).toList();
  }
}

final serviceDonneesVehiculesProvider =
    Provider<ServiceDonneesVehicules>((ref) => ServiceDonneesVehicules());
