library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_manager/presentation/providers/image_picker_provider.dart';

class ImagePreviewWidget extends ConsumerWidget {
  final bool editable;
  final String? existingImagePath;

  const ImagePreviewWidget({
    super.key,
    this.editable = false,
    this.existingImagePath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPath = ref.watch(imagePickerProvider);
    final imagePath = selectedPath ?? existingImagePath;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: editable
          ? () => showImagePickerSheet(context, ref)
          : null,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImageContent(context, imagePath, theme),
              if (editable)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          imagePath != null
                              ? Icons.edit_outlined
                              : Icons.add_a_photo_outlined,
                          size: 14,
                          color: theme.colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          imagePath != null ? 'Cambiar' : 'Agregar foto',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context, String? imagePath, ThemeData theme) {
    if (imagePath != null && File(imagePath).existsSync()) {
      return Image.file(File(imagePath), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(theme));
    }
    return _buildPlaceholder(theme);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.checkroom_outlined, size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        const SizedBox(height: 8),
        Text('Toca para agregar foto',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 13,
            )),
      ],
    );
  }
}
