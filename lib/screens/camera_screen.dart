import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final String title;
  final Function(String)? onPhotoTaken;

  const CameraScreen({Key? key, required this.camera, this.title = 'Camera App', this.onPhotoTaken}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  String? _lastImagePath;
  int _photoCount = 0;
  bool _isMobile = false;

  @override
  void initState() {
    super.initState();
    _detectPlatform();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
    _requestPermissions();
  }

  void _detectPlatform() {
    // Detectar si es móvil o escritorio
    if (kIsWeb) {
      _isMobile = false;
    } else {
      try {
        _isMobile = Platform.isAndroid || Platform.isIOS;
      } catch (e) {
        _isMobile = false;
      }
    }
  }

  Future<void> _requestPermissions() async {
    if (!kIsWeb) {
      try {
        // Solicitar permisos necesarios
        await Permission.camera.request();

        if (_isMobile) {
          await Permission.storage.request();
          // Para Android 13+ (API 33+)
          if (await Permission.photos.isDenied) {
            await Permission.photos.request();
          }
        }
      } catch (e) {
        print('Error al solicitar permisos: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      // Tomar la foto
      final XFile image = await _controller.takePicture();

      String savedLocation = '';

      // Guardar según la plataforma
      if (_isMobile) {
        // Guardar en la galería (móvil)
        await Gal.putImage(image.path, album: 'CameraApp');
        savedLocation = 'Galería (álbum: CameraApp)';
        _photoCount++;
      } else {
        // Para escritorio (Windows, macOS, Linux)
        try {
          final String downloadsPath = _getDownloadsPath();
          final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final String fileName = 'camera_shot_$timestamp.jpg';
          final String filePath = '$downloadsPath${Platform.pathSeparator}$fileName';

          await File(image.path).copy(filePath);
          savedLocation = filePath;
          _photoCount++;
        } catch (e) {
          // Si falla, guardar en la ubicación temporal
          savedLocation = image.path;
          _photoCount++;
        }
      }

      setState(() {
        _lastImagePath = image.path;
      });

      // Notificar al HomeScreen de la foto tomada
      widget.onPhotoTaken?.call(image.path);

      // Mostrar mensaje de confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Foto guardada en: $savedLocation'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      print('Error al tomar la foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _getDownloadsPath() {
    try {
      if (Platform.isWindows) {
        final String? userProfile = Platform.environment['USERPROFILE'];
        return userProfile != null ? '$userProfile\\Downloads' : '';
      } else if (Platform.isMacOS || Platform.isLinux) {
        final String? home = Platform.environment['HOME'];
        return home != null ? '$home/Downloads' : '';
      }
    } catch (e) {
      print('Error al obtener ruta de descargas: $e');
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_photoCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  'Fotos: $_photoCount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: CameraPreview(_controller),
                    ),
                  ),
                ),
                Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _takePicture,
                        icon: const Icon(Icons.camera_alt, size: 28),
                        label: const Text(
                          'Camera Shot',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isMobile
                            ? 'Las fotos se guardan en la Galería'
                            : 'Las fotos se guardan en Descargas',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      if (_lastImagePath != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '✓ Última foto guardada correctamente',
                            style: TextStyle(
                              color: Colors.green[300],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
