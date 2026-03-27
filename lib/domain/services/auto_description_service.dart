library;

final class AutoDescriptionService {
  const AutoDescriptionService();

  String generate({
    required String name,
    required String owner,
    String? categoryName,
  }) {
    final category = categoryName?.toLowerCase().trim();
    final detail   = _detailForCategory(category, name);
    final care     = _careForCategory(category);
    final date     = _formattedDate(DateTime.now());
    return '$detail $care Registrada por $owner el $date.';
  }

  String _detailForCategory(String? category, String name) {
    if (category == null) return '$name lista para lavanderia.';
    return switch (category) {
      'camisa'       => '$name, camisa de vestir. Prenda delicada que requiere cuidado especial.',
      'camiseta'     => '$name, camiseta de uso diario. Prenda casual para lavado regular.',
      'pantalon' || 'pantalón' => '$name, pantalon. Prenda de uso frecuente con tela resistente.',
      'pantaloneta'  => '$name, pantaloneta. Prenda ligera apta para lavado rapido.',
      'chaqueta'     => '$name, chaqueta exterior. Puede requerir lavado especial segun el material.',
      'buso'         => '$name, buso o sudadera. Prenda de abrigo para cuidado moderado.',
      _              => '$name, categoria $category. Prenda registrada para seguimiento.',
    };
  }

  String _careForCategory(String? category) {
    if (category == null) return 'Revisar etiqueta antes de lavar.';
    return switch (category) {
      'camisa'       => 'Lavar a 30C, planchar a temperatura media.',
      'camiseta'     => 'Lavar a 40C, secado normal.',
      'pantalon' || 'pantalón' => 'Lavar a 30C, no centrifugar en exceso.',
      'pantaloneta'  => 'Lavar a 40C, secado rapido.',
      'chaqueta'     => 'Revisar etiqueta. Posible lavado en seco.',
      'buso'         => 'Lavar a 30C, secar en plano para mantener la forma.',
      _              => 'Revisar etiqueta antes de lavar.',
    };
  }

  String _formattedDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
