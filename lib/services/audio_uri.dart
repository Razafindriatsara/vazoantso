/// Prépare une URI lisible par just_audio à partir d'octets,
/// selon la plateforme (fichier temporaire sur mobile, blob sur web).
export 'audio_uri_io.dart' if (dart.library.js_interop) 'audio_uri_web.dart';
