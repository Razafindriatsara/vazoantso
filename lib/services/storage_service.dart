import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/song_folder.dart';

/// Stockage cloud partagé (Firestore) : les chansons sont synchronisées
/// entre tous les appareils.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _folders =>
      _db.collection('folders');
  CollectionReference<Map<String, dynamic>> get _blobs =>
      _db.collection('blobs');

  static const int _chunkSize = 700 * 1024;

  final Map<String, SongFolder> _cache = {};

  Future<void> init() async {}

  String sanitize(String title) =>
      title.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

  SongFolder _fromData(String title, Map<String, dynamic>? data) {
    final files = Map<String, String>.from((data?['files'] as Map?) ?? {});
    final folder = SongFolder(title: title, files: files);
    _cache[title] = folder;
    return folder;
  }

  SongFolder getFolder(String title) =>
      _cache[title] ?? SongFolder(title: title, files: const {});

  Future<Map<String, dynamic>> _folderData(String title) async {
    final doc = await _folders.doc(title).get();
    return doc.data() ?? {};
  }

  Future<List<SongFolder>> listFolders({String query = ''}) async {
    final snap = await _folders.get();
    final q = query.trim().toLowerCase();
    final list = snap.docs
        .map((d) => _fromData(d.id, d.data()))
        .where((f) => q.isEmpty || f.title.toLowerCase().contains(q))
        .toList()
      ..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list;
  }

  Future<SongFolder> createFolder(String title) async {
    final clean = sanitize(title);
    if (clean.isEmpty) throw StateError('Titre vide.');
    final doc = await _folders.doc(clean).get();
    if (doc.exists) throw StateError('Un dossier « $clean » existe déjà.');
    await _folders.doc(clean).set({'files': {}, 'chunks': {}});
    return _fromData(clean, {'files': {}});
  }

  Future<void> _deleteChunks(String title, String suffix, int count) async {
    for (var i = 0; i < count; i++) {
      await _blobs.doc('$title::$suffix::$i').delete();
    }
  }

  Future<void> deleteFolder(SongFolder folder) async {
    final data = await _folderData(folder.title);
    final chunks = Map<String, dynamic>.from((data['chunks'] as Map?) ?? {});
    for (final e in chunks.entries) {
      await _deleteChunks(folder.title, e.key, (e.value as num).toInt());
    }
    await _folders.doc(folder.title).delete();
    _cache.remove(folder.title);
  }

  /// Renomme le dossier ET tous ses fichiers.
  Future<SongFolder> renameFolder(SongFolder folder, String newTitle) async {
    final clean = sanitize(newTitle);
    if (clean.isEmpty) throw StateError('Titre vide.');
    if (clean == folder.title) return folder;
    final target = await _folders.doc(clean).get();
    if (target.exists) throw StateError('Un dossier « $clean » existe déjà.');

    final data = await _folderData(folder.title);
    final files = Map<String, dynamic>.from((data['files'] as Map?) ?? {});
    final chunks = Map<String, dynamic>.from((data['chunks'] as Map?) ?? {});

    final newFiles = <String, String>{};
    for (final e in files.entries) {
      final suffix = e.key;
      final oldName = e.value as String;
      final dot = oldName.lastIndexOf('.');
      final ext = dot >= 0 ? oldName.substring(dot) : '';
      newFiles[suffix] = '${clean}_$suffix$ext';
      final n = ((chunks[suffix] as num?) ?? 0).toInt();
      for (var i = 0; i < n; i++) {
        final chunk =
            await _blobs.doc('${folder.title}::$suffix::$i').get();
        final chunkData = chunk.data();
        if (chunkData != null) {
          await _blobs.doc('$clean::$suffix::$i').set(chunkData);
        }
      }
      await _deleteChunks(folder.title, suffix, n);
    }
    await _folders.doc(clean).set({'files': newFiles, 'chunks': chunks});
    await _folders.doc(folder.title).delete();
    _cache.remove(folder.title);
    return _fromData(clean, {'files': newFiles});
  }

  /// Importe un fichier dans un emplacement. Remplace l'existant.
  Future<SongFolder> importFile(SongFolder folder, SongSlot slot,
      String sourceName, Uint8List bytes) async {
    final dot = sourceName.lastIndexOf('.');
    final ext = dot >= 0 ? sourceName.substring(dot).toLowerCase() : '';
    await writeBytes(folder, slot, bytes);
    final data = await _folderData(folder.title);
    final files = Map<String, dynamic>.from((data['files'] as Map?) ?? {});
    files[slot.suffix] = '${folder.title}_${slot.suffix}$ext';
    await _folders
        .doc(folder.title)
        .set({'files': files}, SetOptions(merge: true));
    return _fromData(folder.title, {...data, 'files': files});
  }

  Future<void> writeBytes(
      SongFolder folder, SongSlot slot, List<int> bytes) async {
    final data = Uint8List.fromList(bytes);
    final oldData = await _folderData(folder.title);
    final chunks =
        Map<String, dynamic>.from((oldData['chunks'] as Map?) ?? {});
    final oldN = ((chunks[slot.suffix] as num?) ?? 0).toInt();
    var n = (data.length / _chunkSize).ceil();
    if (n == 0) n = 1;
    for (var i = 0; i < n; i++) {
      final start = i * _chunkSize;
      final end = (start + _chunkSize) > data.length
          ? data.length
          : start + _chunkSize;
      await _blobs
          .doc('${folder.title}::${slot.suffix}::$i')
          .set({'b': Blob(data.sublist(start, end))});
    }
    for (var i = n; i < oldN; i++) {
      await _blobs.doc('${folder.title}::${slot.suffix}::$i').delete();
    }
    chunks[slot.suffix] = n;
    await _folders
        .doc(folder.title)
        .set({'chunks': chunks}, SetOptions(merge: true));
  }

  Future<Uint8List?> readBytes(SongFolder folder, SongSlot slot) async {
    final data = await _folderData(folder.title);
    final chunks = Map<String, dynamic>.from((data['chunks'] as Map?) ?? {});
    final n = ((chunks[slot.suffix] as num?) ?? 0).toInt();
    if (n == 0) return null;
    final builder = BytesBuilder(copy: false);
    for (var i = 0; i < n; i++) {
      final doc =
          await _blobs.doc('${folder.title}::${slot.suffix}::$i').get();
      final blob = doc.data()?['b'] as Blob?;
      if (blob == null) return null;
      builder.add(blob.bytes);
    }
    return builder.toBytes();
  }

  Future<SongFolder> deleteFile(SongFolder folder, SongSlot slot) async {
    final data = await _folderData(folder.title);
    final files = Map<String, dynamic>.from((data['files'] as Map?) ?? {});
    final chunks = Map<String, dynamic>.from((data['chunks'] as Map?) ?? {});
    final n = ((chunks[slot.suffix] as num?) ?? 0).toInt();
    await _deleteChunks(folder.title, slot.suffix, n);
    files.remove(slot.suffix);
    chunks.remove(slot.suffix);
    await _folders.doc(folder.title).set({'files': files, 'chunks': chunks});
    return _fromData(folder.title, {'files': files, 'chunks': chunks});
  }
}
