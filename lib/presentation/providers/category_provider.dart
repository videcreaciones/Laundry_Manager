library;

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:laundry_manager/domain/entities/category_entity.dart';

const String kCategoryBoxName = 'categories';

class CategoryNotifier extends Notifier<List<CategoryEntity>> {
  late Box _box;

  @override
  List<CategoryEntity> build() {
    _box = Hive.box(kCategoryBoxName);
    return _loadCategories();
  }

  List<CategoryEntity> _loadCategories() {
    final stored = _box.get('categories');
    if (stored == null) {
      // Primera vez — cargar categorías por defecto
      _persist(kDefaultCategories);
      return kDefaultCategories;
    }
    final list = (jsonDecode(stored) as List).map((e) {
      final m = e as Map<String, dynamic>;
      return CategoryEntity(
              id: m['id'] as String,
              name: m['name'] as String,
              isDefault: m['isDefault'] as bool? ?? false,
            );
          }).toList();
    return list;
  }

  void _persist(List<CategoryEntity> categories) {
    _box.put('categories', jsonEncode(categories
        .map((c) => {'id': c.id, 'name': c.name, 'isDefault': c.isDefault})
        .toList()));
  }

  void addCategory(String name) {
    if (name.trim().isEmpty) return;
    final id = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    final updated = [...state, CategoryEntity(id: id, name: name.trim())];
    state = updated;
    _persist(updated);
  }

  void editCategory(String id, String newName) {
    if (newName.trim().isEmpty) return;
    final updated = state.map((c) =>
      c.id == id ? c.copyWith(name: newName.trim()) : c).toList();
    state = updated;
    _persist(updated);
  }

  void deleteCategory(String id) {
    // No borrar categorías por defecto
    final cat = state.firstWhere((c) => c.id == id, orElse: () => const CategoryEntity(id: '', name: ''));
    if (cat.isDefault) return;
    final updated = state.where((c) => c.id != id).toList();
    state = updated;
    _persist(updated);
  }
}

final categoryProvider =
    NotifierProvider<CategoryNotifier, List<CategoryEntity>>(CategoryNotifier.new);


