import 'dart:io';

void main() {
  final serverTimeStr = DateTime.now()
      .subtract(const Duration(minutes: 1))
      .toIso8601String();
  final serverTime = DateTime.parse(serverTimeStr);
  stdout.writeln(DateTime.now().difference(serverTime).inMinutes);
}
