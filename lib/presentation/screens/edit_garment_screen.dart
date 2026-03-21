library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/presentation/providers/category_provider.dart';
import 'package:laundry_manager/presentation/providers/garment_provider.dart';
import 'package:laundry_manager/presentation/providers/image_picker_provider.dart';
import 'package:laundry_manager/presentation/widgets/image_preview_widget.dart';

class EditGarmentScreen extends ConsumerStatefulWidget {
  final GarmentEntity garment;
  const EditGarmentScreen({super.key, required this.garment});

  @override
  ConsumerState<EditGarmentScreen> createState() => _EditGarmentScreenState();
}

class _EditGarmentScreenState extends ConsumerState<EditGarmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ownerController;
  late final TextEditingController _notesController;
  String? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController  = TextEditingController(text: widget.garment.name);
    _ownerController = TextEditingController(text: widget.garment.owner);
    _notesController = TextEditingController(text: widget.garment.notes ?? '');
    _selectedCategoryId = widget.garment.categoryId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(imagePickerProvider.notifier).setImage(widget.garment.imagePath);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _notesController.dispose();
    ref.read(imagePickerProvider.notifier).clearImage();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final imagePath = ref.read(imagePickerProvider);
    try {
      await ref.read(garmentNotifierProvider.notifier).editGarment(
        original:   widget.garment,
        name:       _nameController.text.trim(),
        owner:      _ownerController.text.trim(),
        imagePath:  imagePath,
        notes:      _notesController.text.trim().isEmpty
                        ? null : _notesController.text.trim(),
        categoryId: _selectedCategoryId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prenda actualizada correctamente')));
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar prenda'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
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
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El propietario es requerido' : null,
            ),
            const SizedBox(height: 16),

            // ── Categoría (opcional) ──────────────────────────────────
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Categoría (opcional)',
                prefixIcon: Icon(Icons.label_outline),
                border: OutlineInputBorder(),
              ),
              hint: const Text('Sin categoría'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Sin categoría')),
                ...categories.map((cat) => DropdownMenuItem(
                  value: cat.id,
                  child: Text(cat.name),
                )),
              ],
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                prefixIcon: Icon(Icons.notes_outlined),
                border: OutlineInputBorder(),
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
