library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_manager/presentation/providers/category_provider.dart';
import 'package:laundry_manager/presentation/providers/garment_provider.dart';
import 'package:laundry_manager/presentation/providers/image_picker_provider.dart';
import 'package:laundry_manager/domain/services/auto_description_service.dart';
import 'package:laundry_manager/presentation/providers/settings_provider.dart';
import 'package:laundry_manager/presentation/widgets/image_preview_widget.dart';

class AddGarmentScreen extends ConsumerStatefulWidget {
  const AddGarmentScreen({super.key});

  @override
  ConsumerState<AddGarmentScreen> createState() => _AddGarmentScreenState();
}

class _AddGarmentScreenState extends ConsumerState<AddGarmentScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _nameController  = TextEditingController();
  final _ownerController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Limpiar imagen al entrar — siempre empieza sin foto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(imagePickerProvider.notifier).clearImage();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _generateDescription(String name, String? categoryId) {
    final categories   = ref.read(categoryProvider);
    final categoryName = categoryId != null
        ? categories.where((c) => c.id == categoryId).firstOrNull?.name
        : null;
    return const AutoDescriptionService().generate(
      name:         name,
      owner:        _ownerController.text.trim(),
      categoryName: categoryName,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final imagePath  = ref.read(imagePickerProvider);
    final autoFill   = ref.read(settingsProvider).autoFill;
    final name       = _nameController.text.trim();
    final notes      = _notesController.text.trim().isEmpty
        ? (autoFill ? _generateDescription(name, _selectedCategoryId) : null)
        : _notesController.text.trim();

    try {
      await ref.read(garmentNotifierProvider.notifier).addGarment(
        name:       name,
        owner:      _ownerController.text.trim(),
        imagePath:  imagePath,
        notes:      notes,
        categoryId: _selectedCategoryId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prenda registrada correctamente')));
        context.pop();
      }
    } on GarmentException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userMessage),
              backgroundColor: Theme.of(context).colorScheme.error));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final autoFill   = ref.watch(settingsProvider).autoFill;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva prenda'),
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Guardar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const ImagePreviewWidget(editable: true),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la prenda *',
                hintText: 'Ej: Camisa azul manga larga',
                prefixIcon: Icon(Icons.checkroom_outlined),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El nombre es requerido' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _ownerController,
              decoration: const InputDecoration(
                labelText: 'Propietario *',
                hintText: 'Ej: Juan Pérez',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El propietario es requerido' : null,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Categoría (opcional)',
                prefixIcon: Icon(Icons.label_outline),
                border: OutlineInputBorder(),
              ),
              hint: const Text('Sin categoría'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Sin categoría')),
                ...categories.map((cat) => DropdownMenuItem(
                  value: cat.id, child: Text(cat.name))),
              ],
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: autoFill
                    ? 'Notas (se generará automáticamente si está vacío)'
                    : 'Notas (opcional)',
                hintText: autoFill
                    ? 'Dejar vacío para generar automáticamente'
                    : 'Ej: Lavar en frío, no centrifugar',
                prefixIcon: const Icon(Icons.notes_outlined),
                border: const OutlineInputBorder(),
                suffixIcon: autoFill
                    ? const Tooltip(
                        message: 'El relleno automático está activado',
                        child: Icon(Icons.auto_awesome, size: 18))
                    : null,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            Text('* Campos requeridos',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}



