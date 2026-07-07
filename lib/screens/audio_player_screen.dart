import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song_folder.dart';
import '../services/audio_uri.dart';
import '../services/storage_service.dart';

/// Lecteur audio simple : lecture/pause, barre de progression, ±10 s.
/// Fonctionne sur iOS, Android et le web.
class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({
    super.key,
    required this.folder,
    required this.slot,
    required this.title,
  });

  final SongFolder folder;
  final SongSlot slot;
  final String title;

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final _player = AudioPlayer();
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final bytes = await StorageService.instance
          .readBytes(widget.folder, widget.slot);
      if (bytes == null) throw StateError('Fichier introuvable.');
      final name =
          widget.folder.fileNameFor(widget.slot) ?? 'audio.mp3';
      final uri = await prepareAudioUri(name, bytes);
      await _player.setAudioSource(AudioSource.uri(uri));
      _player.play();
    } catch (e) {
      if (mounted) setState(() => _error = 'Lecture impossible : $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(widget.title, overflow: TextOverflow.ellipsis)),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.music_note,
                        size: 96,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 32),
                    StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final duration = _player.duration ?? Duration.zero;
                        return Column(
                          children: [
                            Slider(
                              value: position.inMilliseconds
                                  .clamp(0, duration.inMilliseconds)
                                  .toDouble(),
                              max: duration.inMilliseconds
                                  .toDouble()
                                  .clamp(1, double.infinity),
                              onChanged: (v) => _player.seek(
                                  Duration(milliseconds: v.round())),
                            ),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_fmt(position)),
                                Text(_fmt(duration)),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.replay_10),
                          onPressed: () => _player.seek(_player.position -
                              const Duration(seconds: 10)),
                        ),
                        const SizedBox(width: 16),
                        StreamBuilder<PlayerState>(
                          stream: _player.playerStateStream,
                          builder: (context, snapshot) {
                            final playing =
                                snapshot.data?.playing ?? false;
                            final completed =
                                snapshot.data?.processingState ==
                                    ProcessingState.completed;
                            return FilledButton(
                              style: FilledButton.styleFrom(
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(20),
                              ),
                              onPressed: () {
                                if (completed) {
                                  _player.seek(Duration.zero);
                                  _player.play();
                                } else if (playing) {
                                  _player.pause();
                                } else {
                                  _player.play();
                                }
                              },
                              child: Icon(
                                completed
                                    ? Icons.replay
                                    : (playing
                                        ? Icons.pause
                                        : Icons.play_arrow),
                                size: 36,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.forward_10),
                          onPressed: () => _player.seek(_player.position +
                              const Duration(seconds: 10)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
