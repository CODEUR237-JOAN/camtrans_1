import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    final content = file.readAsStringSync();
    final emojis = <String>{};
    for (int i = 0; i < content.length; i++) {
      int code = content.codeUnitAt(i);
      // Surrogate pairs in UTF-16 indicate emojis/symbols
      if (code >= 0xD800 && code <= 0xDBFF) {
         if (i + 1 < content.length) {
            final next = content.codeUnitAt(i+1);
            if (next >= 0xDC00 && next <= 0xDFFF) {
               emojis.add(content.substring(i, i+2));
            }
         }
      }
    }
    if (emojis.isNotEmpty) {
      print('${file.path} contains: ${emojis.join(" ")}');
    }
  }
}
