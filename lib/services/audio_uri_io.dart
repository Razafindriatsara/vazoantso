import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// iOS / Android : écrit les octets dans un fichier temporaire.
Future<Uri> prepareAudioUri(String name, Uint8List bytes) async {
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, name));
  await file.writeAsBytes(bytes, flush: true);
  return Uri.file(file.path);
}
