import 'dart:io';

void main() {
  final dir = Directory('lib');
  if (!dir.existsSync()) {
    print('lib directory not found');
    return;
  }

  int count = 0;
  final regex = RegExp(r'\.withOpacity\((.*?)\)');

  for (var file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      String content = file.readAsStringSync();
      bool changed = false;
      
      if (content.contains('.withOpacity(')) {
        content = content.replaceAllMapped(regex, (match) {
          return '.withValues(alpha: ${match.group(1)})';
        });
        changed = true;
      }
      
      if (content.contains('activeColor:') && file.path.contains('tableau_de_bord_transporteur.dart')) {
        content = content.replaceAll('activeColor:', 'activeThumbColor:');
        changed = true;
      }
      
      if (content.contains("import 'dart:ui';")) {
        content = content.replaceAll("import 'dart:ui';", "");
        changed = true;
      }
      
      if (content.contains("foregroundColor:") && file.path.contains("ticket_recu.dart")) {
         content = content.replaceAll("foregroundColor:", "dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color:");
         content = content.replaceAll("), // foregroundColor", "), ),"); // This is too tricky for simple replace. Let's skip it and fix ticket_recu manually.
      }

      if (changed) {
        file.writeAsStringSync(content);
        count++;
        print('Updated ${file.path}');
      }
    }
  }
  print('Updated $count files.');
}
