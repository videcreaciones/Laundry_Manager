library;

final class CategoryEntity {
  final String id;
  final String name;
  final bool isDefault;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  CategoryEntity copyWith({String? name}) {
    return CategoryEntity(id: id, name: name ?? this.name, isDefault: isDefault);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CategoryEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CategoryEntity(id: $id, name: $name)';
}

/// Categorías por defecto que vienen preinstaladas
final kDefaultCategories = [
  const CategoryEntity(id: 'cat_camisa',      name: 'Camisa',      isDefault: true),
  const CategoryEntity(id: 'cat_camiseta',    name: 'Camiseta',    isDefault: true),
  const CategoryEntity(id: 'cat_pantalon',    name: 'Pantalón',    isDefault: true),
  const CategoryEntity(id: 'cat_pantaloneta', name: 'Pantaloneta', isDefault: true),
  const CategoryEntity(id: 'cat_chaqueta',    name: 'Chaqueta',    isDefault: true),
  const CategoryEntity(id: 'cat_buso',        name: 'Buso',        isDefault: true),
];
