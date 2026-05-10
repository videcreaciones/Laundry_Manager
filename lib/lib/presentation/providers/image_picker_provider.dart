library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  Future<void> pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
      );
      state = file?.path;
    } catch (_) {
      state = null;
    }
  }

  Future<void> pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
      );
      state = file?.path;
    } catch (_) {
      state = null;
    }
  }

  void clearImage() => state = null;
  void setImage(String? path) => state = path;
}

final imagePickerProvider =
    NotifierProvider<ImagePickerNotifier, String?>(ImagePickerNotifier.new);

/// Muestra un bottom sheet para elegir entre cámara y galería.
Future<void> showImagePickerSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Seleccionar foto',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.camera_alt_outlined),
              ),
              title: const Text('Tomar foto'),
              subtitle: const Text('Usar la cámara del dispositivo'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(imagePickerProvider.notifier).pickFromCamera();
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.photo_library_outlined),
              ),
              title: const Text('Elegir de galería'),
              subtitle: const Text('Seleccionar una foto existente'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(imagePickerProvider.notifier).pickFromGallery();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

