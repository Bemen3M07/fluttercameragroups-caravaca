import 'package:flutter/material.dart';
import 'dart:io';

class PictureScreen extends StatelessWidget {
  final String title;
  final String? photoPath;

  const PictureScreen({
    super.key,
    required this.title,
    this.photoPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Menú desplegable per opcions de la foto
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) {
              switch (value) {
                case 'info':
                  if (photoPath != null) {
                    _showPhotoInfo(context);
                  }
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('Informació de la foto'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: photoPath != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Image.file(
                        File(photoPath!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Última foto capturada',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_outlined,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Encara no has fet cap foto',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ves a la càmera per fer la primera!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
      ),
    );
  }

  // Mostra informació de la foto
  void _showPhotoInfo(BuildContext context) {
    if (photoPath == null) return;

    final fileName = photoPath!.split('/').last;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Informació de la foto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nom: $fileName'),
              const SizedBox(height: 8),
              Text('Ruta: $photoPath'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tancar'),
            ),
          ],
        );
      },
    );
  }
}
