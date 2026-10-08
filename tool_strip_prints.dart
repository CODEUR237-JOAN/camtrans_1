import 'dart:io';

void main() {
  final start = RegExp(r'(?<![\w.])(debugPrint|print)\(');
  var total = 0;
  for (final f in Directory('lib').listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) continue;
    var s = f.readAsStringSync();
    var count = 0;
    while (true) {
      final m = start.firstMatch(s);
      if (m == null) break;
      // statement must start a line (after indentation)
      final ls = s.lastIndexOf('\n', m.start) + 1;
      if (s.substring(ls, m.start).trim().isNotEmpty) {
        stderr.writeln('SKIP non-statement ${f.path}: ${s.substring(ls, m.end)}');
        s = s.replaceRange(m.start, m.start + 1, '\u0001${s[m.start]}');
        continue;
      }
      var i = m.end;
      var depth = 1;
      String? q;
      while (i < s.length && depth > 0) {
        final c = s[i];
        if (q != null) {
          if (c == '\\') {
            i++;
          } else if (c == q) {
            q = null;
          }
        } else if (c == "'" || c == '"') {
          q = c;
        } else if (c == '(') {
          depth++;
        } else if (c == ')') {
          depth--;
        }
        i++;
      }
      if (i >= s.length || s[i] != ';') {
        stderr.writeln('SKIP no-semicolon ${f.path}');
        s = s.replaceRange(m.start, m.start + 1, '\u0001${s[m.start]}');
        continue;
      }
      i++;
      var end = i;
      while (end < s.length && (s[end] == ' ' || s[end] == '\t' || s[end] == '\r')) {
        end++;
      }
      if (end < s.length && s[end] == '\n') end++;
      s = s.replaceRange(ls, end, '');
      count++;
    }
    s = s.replaceAll('\u0001', '');
    // catch vides => commentaire
    s = s.replaceAllMapped(
      RegExp(r'(catch\s*\([^)]*\)\s*\{)(\s*)\}'),
      (m) => '${m[1]} /* erreur ignorée */ }',
    );
    s = s.replaceAllMapped(
      RegExp(r'(on\s+[\w<>?]+(?:\s+catch\s*\([^)]*\))?\s*\{)(\s*)\}'),
      (m) => '${m[1]} /* erreur ignorée */ }',
    );
    if (count > 0) {
      f.writeAsStringSync(s);
      stdout.writeln('${f.path}: $count');
      total += count;
    }
  }
  stdout.writeln('TOTAL $total');
}
