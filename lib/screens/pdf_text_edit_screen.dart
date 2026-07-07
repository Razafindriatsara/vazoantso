import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/song_folder.dart';
import '../services/storage_service.dart';

/// Extrait le texte du PDF, permet de l'éditer, puis régénère le PDF.
/// Attention : la mise en page d'origine n'est pas conservée.
class PdfTextEditScreen extends StatefulWidget {
  const PdfTextEditScreen(
      {super.key, required this.folder, required this.slot});

  final SongFolder folder;
  final SongSlot slot;

  @override
  State<PdfTextEditScreen> createState() => _PdfTextEditScreenState();
}

class _PdfTextEditScreenState extends State<PdfTextEditScreen> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _extract();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _extract() async {
    try {
      final bytes = await StorageService.instance
          .readBytes(widget.folder, widget.slot);
      if (bytes != null) {
        final document = PdfDocument(inputBytes: bytes);
        _controller.text = PdfTextExtractor(document).extractText();
        document.dispose();
      }
    } catch (e) {
      _controller.text = '';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Impossible d'extraire le texte : $e")));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final document = PdfDocument();
      document.pageSettings.size = PdfPageSize.a4;
      document.pageSettings.margins.all = 40;
      final font = PdfStandardFont(PdfFontFamily.helvetica, 14);
      final page = document.pages.add();
      final layoutFormat = PdfLayoutFormat(
        layoutType: PdfLayoutType.paginate,
        breakType: PdfLayoutBreakType.fitPage,
      );
      PdfTextElement(text: _controller.text, font: font).draw(
        page: page,
        bounds: Rect.fromLTWH(0, 0, page.getClientSize().width,
            page.getClientSize().height),
        format: layoutFormat,
      );
      final bytes = await document.save();
      document.dispose();
      await StorageService.instance
          .writeBytes(widget.folder, widget.slot, bytes);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le texte'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Enregistrer en PDF',
                  onPressed: _save,
                ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: const Text(
                    "L'enregistrement régénère le PDF à partir du texte : "
                    'la mise en page d\'origine sera remplacée.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Paroles…',
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
