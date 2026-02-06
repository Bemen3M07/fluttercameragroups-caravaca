import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicScreen extends StatefulWidget {
  final String title;

  const MusicScreen({
    super.key,
    required this.title,
  });

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  // Configura els listeners del reproductor
  void _setupAudioPlayer() {
    // Listener per la duració total
    _audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        _duration = d;
      });
    });

    // Listener per la posició actual
    _audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() {
        _position = p;
      });
    });

    // Listener per quan acaba la cançó
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });

    // Listener per l'estat del reproductor
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    // Carreguem l'àudio per defecte (des dels assets)
    _loadAudio();
  }

  // Carrega l'àudio des dels assets
  Future<void> _loadAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('audio/sample.mp3'));
    } catch (e) {
      debugPrint('Error al carregar l\'àudio: $e');
    }
  }

  // Reprodueix o pausa l'àudio
  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    } catch (e) {
      debugPrint('Error al reproduir/pausar: $e');
    }
  }

  // Atura l'àudio i torna al principi
  Future<void> _stop() async {
    await _audioPlayer.stop();
    setState(() {
      _position = Duration.zero;
    });
    await _loadAudio();
  }

  // Retrocedeix 10 segons
  Future<void> _rewind() async {
    final newPosition = _position - const Duration(seconds: 10);
    await _audioPlayer.seek(newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  // Avança 10 segons
  Future<void> _forward() async {
    final newPosition = _position + const Duration(seconds: 10);
    if (newPosition < _duration) {
      await _audioPlayer.seek(newPosition);
    } else {
      await _audioPlayer.seek(_duration);
    }
  }

  // Canvia la velocitat de reproducció
  Future<void> _changeSpeed(double speed) async {
    setState(() {
      _playbackSpeed = speed;
    });
    await _audioPlayer.setPlaybackRate(speed);
  }

  // Formata la duració a mm:ss
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Menú desplegable amb opcions del reproductor
        actions: [
          PopupMenuButton<double>(
            icon: const Icon(Icons.speed),
            tooltip: 'Velocitat de reproducció',
            onSelected: _changeSpeed,
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<double>(
                value: 0.5,
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      color: _playbackSpeed == 0.5 ? Colors.blue : Colors.transparent,
                    ),
                    const SizedBox(width: 8),
                    const Text('0.5x (Lent)'),
                  ],
                ),
              ),
              PopupMenuItem<double>(
                value: 1.0,
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      color: _playbackSpeed == 1.0 ? Colors.blue : Colors.transparent,
                    ),
                    const SizedBox(width: 8),
                    const Text('1.0x (Normal)'),
                  ],
                ),
              ),
              PopupMenuItem<double>(
                value: 1.5,
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      color: _playbackSpeed == 1.5 ? Colors.blue : Colors.transparent,
                    ),
                    const SizedBox(width: 8),
                    const Text('1.5x (Ràpid)'),
                  ],
                ),
              ),
              PopupMenuItem<double>(
                value: 2.0,
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      color: _playbackSpeed == 2.0 ? Colors.blue : Colors.transparent,
                    ),
                    const SizedBox(width: 8),
                    const Text('2.0x (Molt ràpid)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icona del reproductor
            Icon(
              _isPlaying ? Icons.music_note : Icons.music_off,
              size: 120,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),

            // Títol de la cançó
            Text(
              'Sample Audio',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),

            // Velocitat actual
            Text(
              'Velocitat: ${_playbackSpeed}x',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // Barra de progrés
            Slider(
              value: _position.inSeconds.toDouble(),
              min: 0,
              max: _duration.inSeconds.toDouble() > 0
                  ? _duration.inSeconds.toDouble()
                  : 1,
              onChanged: (value) async {
                await _audioPlayer.seek(Duration(seconds: value.toInt()));
              },
            ),

            // Temps actual / Temps total
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position)),
                  Text(_formatDuration(_duration)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Botons de control
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botó retrocedir
                IconButton(
                  onPressed: _rewind,
                  icon: const Icon(Icons.replay_10),
                  iconSize: 40,
                  tooltip: 'Retrocedir 10s',
                ),
                const SizedBox(width: 16),

                // Botó stop
                IconButton(
                  onPressed: _stop,
                  icon: const Icon(Icons.stop),
                  iconSize: 40,
                  tooltip: 'Aturar',
                ),
                const SizedBox(width: 16),

                // Botó play/pause
                FloatingActionButton(
                  onPressed: _togglePlayPause,
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),

                // Botó avançar
                IconButton(
                  onPressed: _forward,
                  icon: const Icon(Icons.forward_10),
                  iconSize: 40,
                  tooltip: 'Avançar 10s',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
