const fs = require('fs');
const file = 'lib/fonctionnalites/client/suivi_transport.dart';
let content = fs.readFileSync(file, 'utf8');

const target1 = `    // ✅ PILIER 1 & 2: Moteur d'Auto-Dispatch côté Client
    if (estClient && course.statut == StatutCourse.recherche) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _executerAutoDispatch(course);
      });
    }`;
content = content.replace(target1, "");

const markerStart = "  bool _rechercheEnCours = false;";
const markerEnd = "  void _afficherTimeoutGlobal(Course course) {";
const parts1 = content.split(markerStart);
const parts2 = parts1[1].split(markerEnd);
const newContent = parts1[0] + markerEnd + parts2[1];

fs.writeFileSync(file, newContent, 'utf8');
console.log('Update complete');
