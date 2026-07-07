// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Web : crée une URL blob à partir des octets.
Future<Uri> prepareAudioUri(String name, Uint8List bytes) async {
  final blob = html.Blob([bytes]);
  return Uri.parse(html.Url.createObjectUrlFromBlob(blob));
}
