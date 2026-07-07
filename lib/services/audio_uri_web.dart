import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Web : crée une URL blob à partir des octets.
Future<Uri> prepareAudioUri(String name, Uint8List bytes) async {
  final blob = web.Blob([bytes.toJS].toJS);
  return Uri.parse(web.URL.createObjectURL(blob));
}
