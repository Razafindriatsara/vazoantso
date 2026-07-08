import 'package:flutter/material.dart';

import '../models/song_folder.dart';
import '../services/storage_service.dart';
import 'folder_screen.dart';

/// Écran d'accueil : catégories Vinavina, Voaboatra, Manamasaka et
/// Playliste (sous-catégories Hiravavaka / Alahamohamo).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  SongStage _stage = SongStage.vinavina;
  List<SongFolder> _folders = [];
  bool _loading = true;

  static const Map<SongStage, Color> _stageColors = {
    SongStage.vinavina: Color(0xFFF59E0B),
    SongStage.voaboatra: Color(0xFF3B82F6),
    SongStage.manamasaka: Color(0xFF22C55E),
    SongStage.hiravavaka: Color(0xFF8B5CF6),
    SongStage.alahamohamo: Color(0xFFEC4899),
  };

  static const Color _playlistColor = Color(0xFF8B5CF6);

  Color get _color => _stageColors[_stage]!;
  bool get _inPlaylist => _stage.isPlaylist;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectStage(SongStage stage) {
    setState(() {
      _stage = stage;
      _loading = true;
    });
    _refresh();
  }

  Future<void> _refresh() async {
    final folders = await StorageService.instance
        .listFolders(query: _searchController.text, stage: _stage);
    if (!mounted) return;
    setState(() {
      _folders = folders;
      _loading = false;
    });
  }

  Future<void> _addFolder() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nouveau chant — ${_stage.label}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Titre du chant',
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
            style: FilledButton.styleFrom(backgroundColor: _color),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    if (title == null || title.trim().isEmpty) return;
    try {
      final folder =
          await StorageService.instance.createFolder(title, stage: _stage);
      await _refresh();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FolderScreen(folder: folder)),
      );
      _refresh();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _move(SongFolder folder, SongStage target) async {
    try {
      await StorageService.instance.moveToStage(folder, target);
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('« ${folder.title} » transféré vers ${target.label}.'),
        backgroundColor: _stageColors[target],
      ));
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _deleteFolder(SongFolder folder) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer « ${folder.title} » ?'),
        content: const Text(
            'Le chant et tous ses fichiers seront supprimés définitivement.'),
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
    await StorageService.instance.deleteFolder(folder);
    _refresh();
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.toString())));
  }

  Widget _mainButton({
    required String label,
    required String description,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
          transform: selected
              ? Matrix4.translationValues(0, -3, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(color, Colors.white, selected ? .25 : .1)!,
                color,
                Color.lerp(color, Colors.black, .3)!,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: selected
                ? Border.all(color: Colors.white, width: 2)
                : Border.all(
                    color: Color.lerp(color, Colors.black, .2)!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(color, Colors.black, .4)!
                    .withOpacity(selected ? .6 : .35),
                offset: Offset(0, selected ? 7 : 4),
                blurRadius: selected ? 12 : 6,
              ),
            ],
          ),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black38),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VazoAntso',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
            child: Row(
              children: [
                for (final stage in const [
                  SongStage.vinavina,
                  SongStage.voaboatra,
                  SongStage.manamasaka,
                ])
                  _mainButton(
                    label: stage.label,
                    description: stage.description,
                    color: _stageColors[stage]!,
                    selected: _stage == stage,
                    onTap: () => _selectStage(stage),
                  ),
                _mainButton(
                  label: 'Playliste',
                  description: 'Hiravavaka · Alahamohamo',
                  color: _playlistColor,
                  selected: _inPlaylist,
                  onTap: () => _selectStage(SongStage.hiravavaka),
                ),
              ],
            ),
          ),
          if (_inPlaylist)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  for (final sub in const [
                    SongStage.hiravavaka,
                    SongStage.alahamohamo,
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(sub.label,
                                textAlign: TextAlign.center),
                          ),
                          selected: _stage == sub,
                          selectedColor:
                              _stageColors[sub]!.withOpacity(.25),
                          onSelected: (_) => _selectStage(sub),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Rechercher dans ${_stage.label}…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _refresh();
                    },
                  ),
              ],
              onChanged: (_) => _refresh(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _folders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.library_music,
                                size: 64, color: _color.withOpacity(.4)),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Aucun chant dans ${_stage.label}.\nAppuyez sur « Ajouter ».'
                                  : 'Aucun résultat.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.builder(
                          itemCount: _folders.length,
                          itemBuilder: (context, i) {
                            final folder = _folders[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _color.withOpacity(.15),
                                child: Icon(Icons.folder, color: _color),
                              ),
                              title: Text(folder.title),
                              subtitle:
                                  Text('${folder.filledSlots}/7 fichiers'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action.startsWith('move:')) {
                                    _move(
                                        folder,
                                        SongStage.fromId(
                                            action.substring(5)));
                                  } else if (action == 'delete') {
                                    _deleteFolder(folder);
                                  }
                                },
                                itemBuilder: (context) => [
                                  for (final target
                                      in folder.stage.nextOptions)
                                    PopupMenuItem(
                                      value: 'move:${target.id}',
                                      child: ListTile(
                                        leading: Icon(Icons.arrow_forward,
                                            color: _stageColors[target]),
                                        title: Text(
                                            'Transférer vers ${target.label}'),
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(Icons.delete_outline),
                                      title: Text('Supprimer'),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FolderScreen(folder: folder),
                                  ),
                                );
                                _refresh();
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFolder,
        backgroundColor: _color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Ajouter — ${_stage.label}'),
      ),
    );
  }
}
