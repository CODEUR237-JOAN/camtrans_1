import 'dart:html' as html;

void telechargerFichier(List<int> bytes, String nomFichier) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute("download", nomFichier)
    ..click();
  html.Url.revokeObjectUrl(url);
}
