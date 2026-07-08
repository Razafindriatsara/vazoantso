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

/// Les étapes de préparation d'un chant.
/// Les deux dernières (hiravavaka, alahamohamo) sont les sous-catégories
/// de la Playliste.
enum SongStage {
  vinavina('vinavina', 'Vinavina', 'Suggestions'),
  voaboatra('voaboatra', 'Voaboatra', 'À retravailler'),
  manamasaka('manamasaka', 'Manamasaka', 'Prêts à répéter'),
  hiravavaka('hiravavaka', 'Hiravavaka', 'Playliste'),
  alahamohamo('alahamohamo', 'Alahamohamo', 'Playliste');

  const SongStage(this.id, this.label, this.description);

  final String id;
  final String label;
  final String description;

  /// Fait partie de la Playliste ?
  bool get isPlaylist => this == hiravavaka || this == alahamohamo;

  /// Destinations de transfert possibles depuis cette étape.
  List<SongStage> get nextOptions => switch (this) {
        vinavina => const [SongStage.voaboatra],
        voaboatra => const [SongStage.manamasaka],
        manamasaka => const [SongStage.hiravavaka, SongStage.alahamohamo],
        _ => const [],
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
