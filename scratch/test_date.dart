
void main() {
  var serverTimeStr = DateTime.now().subtract(Duration(minutes: 1)).toIso8601String();
  var serverTime = DateTime.parse(serverTimeStr);
  print(DateTime.now().difference(serverTime).inMinutes);
}
