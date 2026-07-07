/// Les 7 emplacements de fichiers d'une chanson.
enum SongSlot {
  lyrics('lyrics', 'Lyrics (PDF)'),
  instrum('instrum', 'Instrumental'),
  vocalEnsemble('vocal_ensemble', 'Vocal ensemble'),
  vocal1('vocal_1', 'Vocal 1'),
  vocal2('vocal_2', 'Vocal 2'),
  vocal3('vocal_3', 'Vocal 3'),
  vocal4('vocal_4', 'Vocal 4');

  const SongSlot(this.suffix, this.label);

  /// Suffixe utilisé dans le nom de fichier : `<titre>_<suffix>.<ext>`.
  final String suffix;
  final String label;
}

/// Un dossier de chanson : un titre + jusqu'à 7 fichiers nommés
/// `<titre>_lyrics.pdf`, `<titre>_instrum.mp3`, etc.
/// Fonctionne sur iOS, Android et le web (stockage Hive).
class SongFolder {
  const SongFolder({required this.title, required this.files});

  final String title;

  /// suffixe de l'emplacement -> nom de fichier affiché.
  final Map<String, String> files;

  String? fileNameFor(SongSlot slot) => files[slot.suffix];

  bool hasFile(SongSlot slot) => files.containsKey(slot.suffix);

  /// Nombre de fichiers présents (sur 7).
  int get filledSlots =>
      SongSlot.values.where((s) => files.containsKey(s.suffix)).length;
}
