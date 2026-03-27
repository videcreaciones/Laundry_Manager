library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/presentation/providers/category_provider.dart';
import 'package:laundry_manager/presentation/providers/garment_provider.dart';
import 'package:laundry_manager/presentation/router/app_router.dart';
import 'package:laundry_manager/presentation/widgets/garment_card_widget.dart';

// Sentinel para filtrar prendas sin categoria
const _kNoCategoryId = '__none__';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategoryId; // null = Todos, _kNoCategoryId = Sin categoria

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GarmentEntity> _filtered(List<GarmentEntity> all) {
    return all.where((g) {
      // Filtro de texto
      final matchesQuery = _query.isEmpty ||
          g.name.toLowerCase().contains(_query.toLowerCase()) ||
          g.owner.toLowerCase().contains(_query.toLowerCase());

      // Filtro de categoria
      final matchesCategory = _selectedCategoryId == null
          ? true
          : _selectedCategoryId == _kNoCategoryId
              ? (g.categoryId == null || g.categoryId!.isEmpty)
              : g.categoryId == _selectedCategoryId;

      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final garmentsAsync = ref.watch(garmentNotifierProvider);
    final categories    = ref.watch(categoryProvider);
    final theme         = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar prendas')),
      body: Column(
        children: [
          // ── Barra de búsqueda ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o propietario...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          // ── Chips de categoría ─────────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Todos
                _CategoryChip(
                  label: 'Todos',
                  selected: _selectedCategoryId == null,
                  onTap: () => setState(() => _selectedCategoryId = null),
                ),
                // Sin categoría
                _CategoryChip(
                  label: 'Sin categoría',
                  selected: _selectedCategoryId == _kNoCategoryId,
                  onTap: () => setState(() =>
                    _selectedCategoryId = _selectedCategoryId == _kNoCategoryId
                        ? null : _kNoCategoryId),
                ),
                // Categorías del usuario
                ...categories.map((cat) => _CategoryChip(
                  label: cat.name,
                  selected: _selectedCategoryId == cat.id,
                  onTap: () => setState(() =>
                    _selectedCategoryId = _selectedCategoryId == cat.id
                        ? null : cat.id),
                )),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Resultados ─────────────────────────────────────────────
          Expanded(
            child: garmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (garments) {
                final filtered = _filtered(garments);

                if (_query.isEmpty && _selectedCategoryId == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64,
                            color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text('Escribe o selecciona una categoría',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64,
                            color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text('No se encontraron prendas',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => GarmentCard(
                    garment: filtered[i],
                    onTap: () => context.push(
                      AppRoutes.detailPath(filtered[i].id),
                      extra: filtered[i],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

