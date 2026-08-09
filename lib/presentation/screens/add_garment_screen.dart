library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_manager/presentation/providers/category_provider.dart';
import 'package:laundry_manager/presentation/providers/garment_provider.dart';
import 'package:laundry_manager/presentation/providers/image_picker_provider.dart';
import 'package:laundry_manager/domain/services/auto_description_service.dart';
import 'package:laundry_manager/presentation/providers/settings_provider.dart';
import 'package:laundry_manager/presentation/widgets/glass/glass_scaffold.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Limpiar imagen al entrar — siempre empieza sin foto
      ref.read(imagePickerProvider.notifier).clearImage();

      // Auto-rellenar propietario si está configurado (modo usuario único)
      final settings = ref.read(settingsProvider);
      if (!settings.companyMode &&
          settings.autoFillOwner &&
          settings.singleUserName.trim().isNotEmpty) {
        _ownerController.text = settings.singleUserName.trim();
      }
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

    final settings   = ref.read(settingsProvider);
    final imagePath  = ref.read(imagePickerProvider);
    final name       = _nameController.text.trim();
    final notes      = _notesController.text.trim().isEmpty
        ? (settings.autoFill ? _generateDescription(name, _selectedCategoryId) : null)
        : _notesController.text.trim();

    // Si el campo estaba oculto/vacío, se usa el nombre de usuario único
    final owner = _ownerController.text.trim().isNotEmpty
        ? _ownerController.text.trim()
        : settings.singleUserName.trim();

    try {
      await ref.read(garmentNotifierProvider.notifier).addGarment(
        name:       name,
        owner:      owner,
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
    final settings   = ref.watch(settingsProvider);
    final autoFill   = settings.autoFill;

    // El campo propietario se oculta solo si: hay modo usuario único
    // configurado con auto-relleno activo Y con un nombre real que usar,
    // Y el usuario no pidió explícitamente seguir viéndolo.
    final effectiveAutoFillOwner =
        settings.autoFillOwner && settings.singleUserName.trim().isNotEmpty;
    final showOwnerField = settings.companyMode ||
        !effectiveAutoFillOwner ||
        settings.showOwnerField;

    return GlassScaffold(
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

            if (showOwnerField) ...[
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
            ],

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
            if (showOwnerField)
              Text('* Campos requeridos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}



