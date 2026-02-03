import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CameraHome(),
    );
  }
}

class CameraHome extends StatefulWidget {
  const CameraHome({super.key});

  @override
  State<CameraHome> createState() => _CameraHomeState();
}

class _CameraHomeState extends State<CameraHome> {
  String? _lastImagePath;
  bool _busy = false;

  Future<void> _takePicture() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      await _showAlert('Permission', 'Camera permission was denied.');
      return;
    }

    setState(() => _busy = true);
    try {
      final XFile? photo = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo == null) return; // user cancelled

      final appDir = await getApplicationDocumentsDirectory();
      final picturesDir = Directory('${appDir.path}/Pictures');
      if (!await picturesDir.exists()) await picturesDir.create(recursive: true);

      final filename = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved = await File(photo.path).copy('${picturesDir.path}/$filename');

      setState(() {
        _lastImagePath = saved.path;
      });

      await _showAlert('Image saved', 'Image saved to:\n${saved.path}');
    } catch (e) {
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
      appBar: AppBar(title: const Text('Camera Capture')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_lastImagePath != null) ...[
                Image.file(File(_lastImagePath!), height: 200),
                const SizedBox(height: 12),
                Text('Last image: ${_lastImagePath!}', textAlign: TextAlign.center),
                const SizedBox(height: 20),
              ],
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: _busy ? const Text('Taking...') : const Text('Take Picture'),
                onPressed: _busy ? null : _takePicture,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
