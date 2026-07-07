import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import '../models/song_folder.dart';

/// Stockage local multiplateforme (iOS, Android, Web) basé sur Hive :
/// - box `folders` : titre -> { suffixe d'emplacement : nom de fichier }
/// - lazy box `files` : "titre::suffixe" -> octets du fichier
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  late Box _meta;
  late LazyBox _files;

  Future<void> init() async {
    await Hive.initFlutter('VazoAntso');
    _meta = await Hive.openBox('folders');
    _files = await Hive.openLazyBox('files');
  }

  /// Nettoie un titre pour en faire un nom valide.
  String sanitize(String title) =>
      title.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

  String _fileKey(String title, SongSlot slot) => '$title::${slot.suffix}';

  SongFolder _folderFromMeta(String title) {
    final raw = _meta.get(title);
    return SongFolder(
      title: title,
      files: raw == null ? {} : Map<String, String>.from(raw as Map),
    );
  }

  SongFolder getFolder(String title) => _folderFromMeta(title);

  Future<List<SongFolder>> listFolders({String query = ''}) async {
    final q = query.trim().toLowerCase();
    final titles = _meta.keys
        .cast<String>()
        .where((t) => q.isEmpty || t.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return titles.map(_folderFromMeta).toList();
  }

  Future<SongFolder> createFolder(String title) async {
    final clean = sanitize(title);
    if (clean.isEmpty) throw StateError('Titre vide.');
    if (_meta.containsKey(clean)) {
      throw StateError('Un dossier « $clean » existe déjà.');
    }
    await _meta.put(clean, <String, String>{});
    return _folderFromMeta(clean);
  }

  Future<void> deleteFolder(SongFolder folder) async {
    for (final slot in SongSlot.values) {
      await _files.delete(_fileKey(folder.title, slot));
    }
    await _meta.delete(folder.title);
  }

  /// Renomme le dossier ET tous ses fichiers (le préfixe change avec le titre).
  Future<SongFolder> renameFolder(SongFolder folder, String newTitle) async {
    final clean = sanitize(newTitle);
    if (clean.isEmpty) throw StateError('Titre vide.');
    if (clean == folder.title) return folder;
    if (_meta.containsKey(clean)) {
      throw StateError('Un dossier « $clean » existe déjà.');
    }
    final newFiles = <String, String>{};
    for (final slot in SongSlot.values) {
      final oldKey = _fileKey(folder.title, slot);
      final bytes = await _files.get(oldKey);
      if (bytes != null) {
        await _files.put(_fileKey(clean, slot), bytes);
        await _files.delete(oldKey);
        final ext = p.extension(folder.files[slot.suffix] ?? '');
        newFiles[slot.suffix] = '${clean}_${slot.suffix}$ext';
      }
    }
    await _meta.put(clean, newFiles);
    await _meta.delete(folder.title);
    return _folderFromMeta(clean);
  }

  /// Importe un fichier dans un emplacement. Remplace l'existant.
  Future<SongFolder> importFile(SongFolder folder, SongSlot slot,
      String sourceName, Uint8List bytes) async {
    final ext = p.extension(sourceName).toLowerCase();
    await _files.put(_fileKey(folder.title, slot), bytes);
    final files =
        Map<String, String>.from((_meta.get(folder.title) as Map?) ?? {});
    files[slot.suffix] = '${folder.title}_${slot.suffix}$ext';
    await _meta.put(folder.title, files);
    return _folderFromMeta(folder.title);
  }

  Future<Uint8List?> readBytes(SongFolder folder, SongSlot slot) async {
    final v = await _files.get(_fileKey(folder.title, slot));
    if (v == null) return null;
    return v is Uint8List ? v : Uint8List.fromList(List<int>.from(v as List));
  }

  Future<void> writeBytes(
      SongFolder folder, SongSlot slot, List<int> bytes) async {
    await _files.put(
        _fileKey(folder.title, slot), Uint8List.fromList(bytes));
  }

  Future<SongFolder> deleteFile(SongFolder folder, SongSlot slot) async {
    await _files.delete(_fileKey(folder.title, slot));
    final files =
        Map<String, String>.from((_meta.get(folder.title) as Map?) ?? {});
    files.remove(slot.suffix);
    await _meta.put(folder.title, files);
    return _folderFromMeta(folder.title);
  }
}
