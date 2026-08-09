library;

import 'dart:io';

import 'package:flutter/material.dart';

/// Visor de imagen a pantalla completa con zoom/pan, con animacion Hero
/// desde la miniatura que lo abrio.
class ImageViewerScreen extends StatelessWidget {
  final String imagePath;
  final String heroTag;

  const ImageViewerScreen({
    super.key,
    required this.imagePath,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: heroTag,
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Image.file(File(imagePath)),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
