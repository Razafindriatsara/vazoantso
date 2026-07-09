import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

String _mime(String name) {
  final ext = name.toLowerCase().split('.').last;
  return switch (ext) {
    'mp3' => 'audio/mpeg',
    'm4a' => 'audio/mp4',
    'aac' => 'audio/aac',
    'wav' => 'audio/wav',
    'ogg' => 'audio/ogg',
    'flac' => 'audio/flac',
    _ => 'audio/mpeg',
  };
}

/// Web : crée une URL blob typée à partir des octets
/// (le type MIME est indispensable pour Safari/iPhone).
Future<Uri> prepareAudioUri(String name, Uint8List bytes) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: _mime(name)),
  );
  return Uri.parse(web.URL.createObjectURL(blob));
}
