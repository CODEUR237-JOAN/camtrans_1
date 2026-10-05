import 'dart:io';

void main() {
  var files = [
    'lib/fonctionnalites/client/tableau_de_bord_client.dart',
    'lib/fonctionnalites/client/parametres.dart'
  ];

  for (var path in files) {
    var file = File(path);
    if (!file.existsSync()) continue;
    var content = file.readAsStringSync();
    
    content = content.replaceAll(RegExp(r'const Color\(0xFF08111F\)'), 'Theme.of(context).scaffoldBackgroundColor');
    content = content.replaceAll(RegExp(r'Color\(0xFF08111F\)'), 'Theme.of(context).scaffoldBackgroundColor');
    
    content = content.replaceAll(RegExp(r'const Color\(0xFF10192A\)'), 'Theme.of(context).colorScheme.surface');
    content = content.replaceAll(RegExp(r'Color\(0xFF10192A\)'), 'Theme.of(context).colorScheme.surface');
    
    content = content.replaceAll(RegExp(r'const Color\(0xFF0C1524\)'), 'Theme.of(context).colorScheme.surfaceContainerHighest');
    content = content.replaceAll(RegExp(r'Color\(0xFF0C1524\)'), 'Theme.of(context).colorScheme.surfaceContainerHighest');

    content = content.replaceAll(RegExp(r'Colors\.white70'), 'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)');
    content = content.replaceAll(RegExp(r'Colors\.white54'), 'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)');
    content = content.replaceAll(RegExp(r'Colors\.white38'), 'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)');
    content = content.replaceAll(RegExp(r'Colors\.white24'), 'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)');
    content = content.replaceAll(RegExp(r'Colors\.white12'), 'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)');
    content = content.replaceAll(RegExp(r'Colors\.white'), 'Theme.of(context).colorScheme.onSurface');

    // Remove const from common widgets and structures that might now contain dynamic values
    var elements = ['Scaffold', 'Text', 'Icon', 'BoxDecoration', 'Container', 'Padding', 'Row', 'Column', 'Center', 'SizedBox', 'Expanded', 'ListTile', 'CircleAvatar', 'TextStyle', 'SnackBar', 'AlertDialog', 'EdgeInsets', 'BorderRadius'];
    for (var el in elements) {
      content = content.replaceAll('const $el', el);
    }
    
    // Arrays and maps might also have const removed if they contain dynamic elements
    content = content.replaceAll('const [', '[');
    content = content.replaceAll('const {', '{');
    content = content.replaceAll('const (', '(');

    file.writeAsStringSync(content);
  }
}
