import 'dart:io';
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Conditional import for web camera implementation
import 'src/web_camera_stub.dart'
    if (dart.library.html) 'src/web_camera.dart';

final List<CameraDescription> _availableCameras = [];
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handling to avoid uncaught exceptions breaking into the debugger
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    _showErrorDialog(details.exceptionAsString());
  };

  await runZonedGuarded(() async {
    if (!kIsWeb) {
      try {
        final cams = await availableCameras();
        _availableCameras.addAll(cams);
      } catch (e) {
        debugPrint('availableCameras error: $e');
      }
    } else {
      debugPrint('Running on web: camera initialization skipped.');
    }
    runApp(const MainApp());
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error\n$stack');
    _showErrorDialog(error.toString());
  });
}

void _showErrorDialog(String message) {
  final ctx = navigatorKey.currentState?.context;
  if (ctx != null) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Unexpected error'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
      ),
    );
  } else {
    debugPrint('Could not show dialog: $message');
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: const CameraHome(),
    );
  }
}

class CameraHome extends StatefulWidget {
  const CameraHome({super.key});

  @override
  State<CameraHome> createState() => _CameraHomeState();
}

class _CameraHomeState extends State<CameraHome> with WidgetsBindingObserver {
  CameraController? _controller;
  final GlobalKey<WebCameraWidgetState> _webCamKey = GlobalKey<WebCameraWidgetState>();
  String? _lastImagePath; // on web this will store a data URL
  bool _initializing = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _error = null;
    });

    // If we're running on Web the permission_handler plugin and camera plugin
    // may not be available/implemented in the same way — show a clear message.
    if (kIsWeb) {
      setState(() {
        _error = 'Camera is not supported on Web in this build. Use a mobile device or enable Web camera support.';
        _initializing = false;
      });
      return;
    }

    // Request camera permission and handle platforms where the permission plugin
    // may not be implemented (MissingPluginException)
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _error = 'Camera permission denied.';
          _initializing = false;
        });
        return;
      }
    } on MissingPluginException catch (e) {
      setState(() {
        _error = 'Permissions plugin not available on this platform: $e';
        _initializing = false;
      });
      return;
    } catch (e) {
      setState(() {
        _error = 'Error requesting camera permission: $e';
        _initializing = false;
      });
      return;
    }

    if (_availableCameras.isEmpty) {
      setState(() {
        _error = 'No cameras available on this device.';
        _initializing = false;
      });
      return;
    }

    // Prefer back camera when available
    CameraDescription camera = _availableCameras.first;
    for (final c in _availableCameras) {
      if (c.lensDirection == CameraLensDirection.back) {
        camera = c;
        break;
      }
    }

    _controller = CameraController(camera, ResolutionPreset.high, enableAudio: false);
    try {
      await _controller!.initialize();
      setState(() {
        _initializing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Camera initialization error: $e';
        _initializing = false;
      });
    }
  }

  Future<void> _takePicture() async {
    setState(() => _busy = true);
    try {
      if (kIsWeb) {
        final dataUrl = await _webCamKey.currentState?.capture(triggerDownload: true);
        if (dataUrl == null) throw Exception('Failed to capture from web camera.');
        setState(() => _lastImagePath = dataUrl);
        await _showAlert('Image captured', 'Image captured and downloaded.');
        return;
      }

      if (_controller == null || !_controller!.value.isInitialized) return;

      final XFile file = await _controller!.takePicture();

      final appDir = await getApplicationDocumentsDirectory();
      final picturesDir = Directory('${appDir.path}/Pictures');
      if (!await picturesDir.exists()) await picturesDir.create(recursive: true);

      final filename = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved = await File(file.path).copy('${picturesDir.path}/$filename');

      setState(() => _lastImagePath = saved.path);

      await _showAlert('Image saved', 'Image saved to:\n${saved.path}');
    } catch (e) {
      debugPrint('takePicture error: $e');
      await _showAlert('Error', e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _showAlert(String title, String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (_lastImagePath != null) ...[
              const SizedBox(height: 12),
              Image.file(File(_lastImagePath!), height: 150),
            ]
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Camera Preview')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Expanded(
                child: _initializing
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                        : kIsWeb
                            ? WebCameraWidget(key: _webCamKey)
                            : AspectRatio(
                                aspectRatio: _controller!.value.aspectRatio,
                                child: CameraPreview(_controller!),
                              ),
              ),
              if (_lastImagePath != null) ...[
                const SizedBox(height: 8),
                kIsWeb
                    ? Image.network(_lastImagePath!, height: 120)
                    : Image.file(File(_lastImagePath!), height: 120),
                const SizedBox(height: 8),
                Text(kIsWeb ? 'Captured (downloaded)' : 'Saved: ${_lastImagePath!}', textAlign: TextAlign.center),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: _busy ? const Text('Capturing...') : const Text('Capture'),
                    onPressed: (_busy || _initializing || _controller == null || !_controller!.value.isInitialized) ? null : _takePicture,
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.switch_camera),
                    label: const Text('Switch'),
                    onPressed: (_availableCameras.length < 2 || _initializing) ? null : _switchCamera,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2) return;
    final current = _controller!.description;
    CameraDescription? next;
    for (final c in _availableCameras) {
      if (c.name != current.name) {
        next = c;
        break;
      }
    }
    if (next == null) return;

    setState(() => _initializing = true);
    await _controller?.dispose();
    _controller = CameraController(next, ResolutionPreset.high, enableAudio: false);
    try {
      await _controller!.initialize();
    } catch (e) {
      setState(() => _error = 'Failed switching camera: $e');
    }
    setState(() => _initializing = false);
  }
}
