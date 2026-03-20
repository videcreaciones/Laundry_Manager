/// Provider para la selección de imagen de una prenda.
///
/// Aislado del [GarmentNotifier] para que un fallo en la selección
/// de imagen no afecte el flujo de guardado (RN-03).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Notifier que gestiona la ruta de la foto seleccionada.
///
/// Estado: `String?`
/// - `null` → sin imagen seleccionada
/// - `String` → ruta absoluta local de la foto
class ImagePickerNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Abre la galería y actualiza el estado con la ruta seleccionada.
  ///
  /// Si el usuario cancela o ocurre un error, el estado queda en `null`
  /// y la operación falla silenciosamente (RN-03: foto siempre opcional).
  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
      );
      state = file?.path; // null si el usuario canceló
    } catch (_) {
      // RN-03: fallo silencioso — la prenda se guarda sin imagen
      state = null;
    }
  }

  /// Descarta la imagen seleccionada.
  void clearImage() => state = null;
}

/// Provider global del notifier de imagen.
final imagePickerProvider =
    NotifierProvider<ImagePickerNotifier, String?>(ImagePickerNotifier.new);
