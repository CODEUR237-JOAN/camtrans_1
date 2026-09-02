import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Algorithme de Dispatch et Equité', () {
    test('Prioriser le transporteur avec moins de courses si les distances sont proches (<= 3 km)', () {
      final List<Map<String, dynamic>> candidatsDispo = [
        {'id': 'T1_PROCHE_BEAUCOUP_COURSES', 'distance': 5.0, 'nombreCourses': 10},
        {'id': 'T2_PROCHE_PEU_COURSES', 'distance': 6.0, 'nombreCourses': 2}, // À 1km de plus, mais 8 courses de moins
        {'id': 'T3_LOIN_ZERO_COURSE', 'distance': 15.0, 'nombreCourses': 0}, // Très loin, ne devrait pas être prioritaire malgré 0 courses
        {'id': 'T4_PLUS_PROCHE', 'distance': 4.5, 'nombreCourses': 9}, // Le plus proche, mais 7 courses de plus que T2
      ];
      
      candidatsDispo.sort((a, b) {
        final distA = a['distance'] as double;
        final distB = b['distance'] as double;
        final coursesA = a['nombreCourses'] as int;
        final coursesB = b['nombreCourses'] as int;

        // Si la différence de distance est faible (<= 3.0 km)
        if ((distA - distB).abs() <= 3.0) {
          // On priorise l'équité du travail
          if (coursesA - coursesB >= 2) return 1;
          if (coursesB - coursesA >= 2) return -1;
        }

        // Sinon, tri standard par distance
        return distA.compareTo(distB);
      });

      // Assertions sur l'ordre final:
      
      // 1. T2 doit être premier (différence de distance avec T4 est de 1.5km (<=3), et il a 7 courses de moins).
      expect(candidatsDispo[0]['id'], 'T2_PROCHE_PEU_COURSES');
      
      // 2. T4 doit être deuxième (entre T4 et T1, la diff de distance est 0.5km. La diff de courses est 1 (pas >= 2). 
      // Donc la distance l'emporte, et T4 (4.5km) gagne contre T1 (5.0km)).
      expect(candidatsDispo[1]['id'], 'T4_PLUS_PROCHE');
      
      // 3. T1 doit être troisième.
      expect(candidatsDispo[2]['id'], 'T1_PROCHE_BEAUCOUP_COURSES');
      
      // 4. T3 doit être dernier car malgré ses 0 courses, il est à 15km (différence de > 3km avec tous les autres).
      expect(candidatsDispo[3]['id'], 'T3_LOIN_ZERO_COURSE');
    });
  });
}
