import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../models/song_folder.dart';
import '../services/storage_service.dart';
import 'pdf_text_edit_screen.dart';

/// Visionneuse PDF avec annotations (surlignage, soulignement, barré,
/// gribouillis), édition du texte et remplacement du fichier.
/// Fonctionne sur iOS, Android et le web (lecture depuis la mémoire).
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({
    super.key,
    required this.folder,
    required this.slot,
    required this.title,
  });

  final SongFolder folder;
  final SongSlot slot;
  final String title;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final _controller = PdfViewerController();
  PdfAnnotationMode _mode = PdfAnnotationMode.none;
  bool _dirty = false;
  Uint8List? _bytes;
  Key _viewerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final bytes =
        await StorageService.instance.readBytes(widget.folder, widget.slot);
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _dirty = false;
      _viewerKey = UniqueKey();
    });
  }

  Future<void> _save() async {
    final bytes = await _controller.saveDocument();
    await StorageService.instance
        .writeBytes(widget.folder, widget.slot, bytes);
    if (!mounted) return;
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('PDF enregistré.')));
  }

  Future<void> _replaceFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) return;
    await StorageService.instance
        .importFile(widget.folder, widget.slot, file.name, file.bytes!);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Fichier remplacé.')));
  }

  Future<void> _editText() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PdfTextEditScreen(folder: widget.folder, slot: widget.slot),
      ),
    );
    if (changed == true) await _load();
  }

  void _setMode(PdfAnnotationMode mode) {
    setState(() {
      _mode = _mode == mode ? PdfAnnotationMode.none : mode;
      _controller.annotationMode = _mode;
    });
  }

  Widget _modeButton(PdfAnnotationMode mode, IconData icon, String tooltip) {
    final selected = _mode == mode;
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      isSelected: selected,
      style: selected
          ? IconButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer)
          : null,
      onPressed: () => _setMode(mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (_dirty)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Enregistrer',
              onPressed: _save,
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'edit_text':
                  _editText();
                case 'replace':
                  _replaceFile();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit_text',
                child: ListTile(
                  leading: Icon(Icons.edit_note),
                  title: Text('Modifier le texte'),
                ),
              ),
              PopupMenuItem(
                value: 'replace',
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Remplacer le fichier'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _bytes == null
          ? const Center(child: CircularProgressIndicator())
          : SfPdfViewer.memory(
              _bytes!,
              key: _viewerKey,
              controller: _controller,
              onAnnotationAdded: (_) => setState(() => _dirty = true),
              onAnnotationEdited: (_) => setState(() => _dirty = true),
              onAnnotationRemoved: (_) => setState(() => _dirty = true),
            ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _modeButton(PdfAnnotationMode.highlight, Icons.border_color,
                'Surligner'),
            _modeButton(PdfAnnotationMode.underline,
                Icons.format_underline, 'Souligner'),
            _modeButton(PdfAnnotationMode.strikethrough,
                Icons.format_strikethrough, 'Barrer'),
            _modeButton(
                PdfAnnotationMode.squiggly, Icons.gesture, 'Gribouillis'),
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Annuler la dernière annotation',
              onPressed: () {
                final annotations = _controller.getAnnotations();
                if (annotations.isNotEmpty) {
                  _controller.removeAnnotation(annotations.last);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
