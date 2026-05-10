library;

final class AutoDescriptionService {
  const AutoDescriptionService();

  String generate({
    required String name,
    required String owner,
    String? categoryName,
  }) {
    final date     = _formattedDate(DateTime.now());
    final category = categoryName ?? 'prenda';
    return '$name. ${_visualHint(name, category)} Lista para lavar. '
           'Propietario: $owner. Registrada el $date.';
  }

  /// Genera una pista visual basada en palabras clave del nombre de la prenda.
  String _visualHint(String name, String category) {
    final n = name.toLowerCase();

    // Color
    final color = _extractColor(n);
    // Patron o estampado
    final pattern = _extractPattern(n);
    // Material
    final material = _extractMaterial(n);

    final parts = [
      if (color != null) color,
      if (pattern != null) pattern,
      if (material != null) 'de $material',
    ];

    if (parts.isNotEmpty) {
      final desc = parts.join(', ');
      return '${_capitalize(category)} $desc.';
    }

    return '${_capitalize(category)} para uso diario.';
  }

  String? _extractColor(String name) {
    const colors = {
      'negro': 'negra',    'negra': 'negra',
      'blanco': 'blanca',  'blanca': 'blanca',
      'azul': 'azul',      'rojo': 'roja',      'roja': 'roja',
      'verde': 'verde',    'amarillo': 'amarilla', 'amarilla': 'amarilla',
      'gris': 'gris',      'cafe': 'cafe',       'marron': 'marron',
      'morado': 'morada',  'rosado': 'rosada',   'rosada': 'rosada',
      'naranja': 'naranja','beige': 'beige',     'vinotinto': 'vinotinto',
      'celeste': 'celeste','turquesa': 'turquesa',
    };
    for (final entry in colors.entries) {
      if (name.contains(entry.key)) return entry.value;
    }
    return null;
  }

  String? _extractPattern(String name) {
    const patterns = {
      'logo':    'con logo',
      'estampa': 'estampada',
      'rayas':   'a rayas',
      'raya':    'a rayas',
      'cuadros': 'a cuadros',
      'liso':    'lisa',
      'lisa':    'lisa',
      'floral':  'floral',
      'manga larga': 'manga larga',
      'manga corta': 'manga corta',
      'slim':    'slim fit',
      'oversize':'oversize',
      'bordado': 'bordada',
    };
    for (final entry in patterns.entries) {
      if (name.contains(entry.key)) return entry.value;
    }
    return null;
  }

  String? _extractMaterial(String name) {
    const materials = {
      'algodon': 'algodon', 'cotton': 'algodon',
      'lino':    'lino',    'jean':  'jean',
      'denim':   'denim',   'seda':  'seda',
      'lana':    'lana',    'poliester': 'poliester',
      'licra':   'licra',   'nylon': 'nylon',
    };
    for (final entry in materials.entries) {
      if (name.contains(entry.key)) return entry.value;
    }
    return null;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formattedDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
