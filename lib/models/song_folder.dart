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

  final String suffix;
  final String label;
}

/// Les 3 étapes de préparation d'un chant.
enum SongStage {
  vinavina('vinavina', 'Vinavina', 'Suggestions'),
  voaboatra('voaboatra', 'Voaboatra', 'À retravailler'),
  manamasaka('manamasaka', 'Manamasaka', 'Prêts à répéter');

  const SongStage(this.id, this.label, this.description);

  final String id;
  final String label;
  final String description;

  /// Étape suivante (null pour la dernière).
  SongStage? get next => switch (this) {
        vinavina => voaboatra,
        voaboatra => manamasaka,
        manamasaka => null,
      };

  static SongStage fromId(String? id) =>
      values.where((s) => s.id == id).firstOrNull ?? vinavina;
}

/// Un dossier de chanson : un titre + jusqu'à 7 fichiers.
class SongFolder {
  const SongFolder({
    required this.title,
    required this.files,
    this.stage = SongStage.vinavina,
  });

  final String title;
  final SongStage stage;

  /// suffixe de l'emplacement -> nom de fichier affiché.
  final Map<String, String> files;

  String? fileNameFor(SongSlot slot) => files[slot.suffix];

  bool hasFile(SongSlot slot) => files.containsKey(slot.suffix);

  int get filledSlots =>
      SongSlot.values.where((s) => files.containsKey(s.suffix)).length;
}
