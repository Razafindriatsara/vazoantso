import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../models/song_folder.dart';
import '../services/storage_service.dart';
import 'audio_player_screen.dart';
import 'pdf_viewer_screen.dart';

/// Écran d'un dossier chanson : les 7 emplacements de fichiers,
/// import / lecture / remplacement / suppression, renommage du titre.
class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key, required this.folder});

  final SongFolder folder;

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  late SongFolder _folder = widget.folder;

  static const _audioExts = ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'];

  bool _isPdfName(String name) => p.extension(name).toLowerCase() == '.pdf';
  bool _isAudioName(String name) => _audioExts
      .contains(p.extension(name).toLowerCase().replaceFirst('.', ''));

  void _reload() {
    setState(
        () => _folder = StorageService.instance.getFolder(_folder.title));
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: _folder.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer la chanson'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nouveau titre',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
    if (newTitle == null || newTitle.trim().isEmpty) return;
    try {
      final renamed =
          await StorageService.instance.renameFolder(_folder, newTitle);
      setState(() => _folder = renamed);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _import(SongSlot slot) async {
    final isLyrics = slot == SongSlot.lyrics;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: isLyrics ? ['pdf'] : [..._audioExts, 'pdf'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) return;
    try {
      await StorageService.instance
          .importFile(_folder, slot, file.name, file.bytes!);
      _reload();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _deleteFile(SongSlot slot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer le fichier « ${slot.label} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await StorageService.instance.deleteFile(_folder, slot);
    _reload();
  }

  Future<void> _open(SongSlot slot) async {
    final name = _folder.fileNameFor(slot);
    if (name == null) return;
    if (_isPdfName(name)) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            folder: _folder,
            slot: slot,
            title: '${_folder.title} — ${slot.label}',
          ),
        ),
      );
    } else if (_isAudioName(name)) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AudioPlayerScreen(
            folder: _folder,
            slot: slot,
            title: '${_folder.title} — ${slot.label}',
          ),
        ),
      );
    } else {
      _showError('Format non pris en charge : ${p.extension(name)}');
    }
    _reload();
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.toString())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_folder.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Renommer',
            onPressed: _rename,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          for (final slot in SongSlot.values) _buildSlotTile(slot),
        ],
      ),
    );
  }

  Widget _buildSlotTile(SongSlot slot) {
    final name = _folder.fileNameFor(slot);
    final exists = name != null;
    final icon = slot == SongSlot.lyrics
        ? Icons.picture_as_pdf
        : (exists && _isPdfName(name)
            ? Icons.picture_as_pdf
            : Icons.music_note);

    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: exists
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
        ),
        title: Text('${_folder.title}_${slot.suffix}'),
        subtitle: Text(exists ? name : '${slot.label} — aucun fichier'),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            switch (action) {
              case 'open':
                _open(slot);
              case 'import':
                _import(slot);
              case 'delete':
                _deleteFile(slot);
            }
          },
          itemBuilder: (context) => [
            if (exists)
              const PopupMenuItem(
                value: 'open',
                child: ListTile(
                    leading: Icon(Icons.play_arrow), title: Text('Ouvrir')),
              ),
            PopupMenuItem(
              value: 'import',
              child: ListTile(
                leading: const Icon(Icons.upload_file),
                title: Text(exists ? 'Remplacer' : 'Importer'),
              ),
            ),
            if (exists)
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                    leading: Icon(Icons.delete_outline),
                    title: Text('Supprimer')),
              ),
          ],
        ),
        onTap: exists ? () => _open(slot) : () => _import(slot),
      ),
    );
  }
}
