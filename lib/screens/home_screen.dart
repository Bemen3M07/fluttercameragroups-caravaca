import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'picture_screen.dart';
import 'music_screen.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _lastPhotoPath;

  void _onPhotoTaken(String path) {
    setState(() {
      _lastPhotoPath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          CameraScreen(
            camera: cameras.isNotEmpty ? cameras.first : cameras.first,
            title: 'Càmera',
            onPhotoTaken: _onPhotoTaken,
          ),
          PictureScreen(
            title: 'Foto',
            photoPath: _lastPhotoPath,
          ),
          const MusicScreen(
            title: 'Música',
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Càmera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo),
            label: 'Foto',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Música',
          ),
        ],
      ),
    );
  }
}
