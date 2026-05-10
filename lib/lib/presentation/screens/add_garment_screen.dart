library;


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_manager/domain/services/auto_description_service.dart';
import 'package:laundry_manager/domain/services/reminder_service.dart';
import 'package:laundry_manager/presentation/providers/category_provider.dart';
import 'package:laundry_manager/presentation/providers/garment_provider.dart';
import 'package:laundry_manager/presentation/providers/image_picker_provider.dart';
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
  ReminderOption? _selectedReminder;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Limpiar imagen al entrar
      ref.read(imagePickerProvider.notifier).clearImage();

      // Auto rellenar propietario si está configurado
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

    final settings  = ref.read(settingsProvider);
    final imagePath = ref.read(imagePickerProvider);
    final name      = _nameController.text.trim();

    // Si autoFillOwner está activo y el campo está vacío, usar el nombre configurado
    final owner = _ownerController.text.trim().isNotEmpty
        ? _ownerController.text.trim()
        : settings.singleUserName.trim();

    final notes = _notesController.text.trim().isEmpty
        ? (settings.autoFill ? _generateDescription(name, _selectedCategoryId) : null)
        : _notesController.text.trim();

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

    // Mostrar campo propietario solo en modo empresa
    // o si NO tiene autoFillOwner activo y showOwnerField está activo
    final showOwnerField = settings.companyMode ||
        (!settings.autoFillOwner && settings.showOwnerField);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva prenda'),
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16, height: 16,
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

            // Nombre
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

            // Propietario — solo visible cuando corresponde
            if (showOwnerField) ...[
              TextFormField(
                controller: _ownerController,
                decoration: const InputDecoration(
                  labelText: 'Propietario *',
                  hintText: 'Ej: Juan Perez',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El propietario es requerido' : null,
              ),
              const SizedBox(height: 16),
            ],

            // Categoría
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Categoria (opcional)',
                prefixIcon: Icon(Icons.label_outline),
                border: OutlineInputBorder(),
              ),
              hint: const Text('Sin categoria'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Sin categoria')),
                ...categories.map((cat) => DropdownMenuItem(
                  value: cat.id, child: Text(cat.name))),
              ],
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
            const SizedBox(height: 16),


            // Notas
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: settings.autoFill
                    ? 'Notas (se genera automaticamente si esta vacio)'
                    : 'Notas (opcional)',
                hintText: 'Ej: Lavar en frio, no centrifugar',
                prefixIcon: const Icon(Icons.notes_outlined),
                border: const OutlineInputBorder(),
                suffixIcon: settings.autoFill
                    ? const Tooltip(
                        message: 'Relleno automatico activado',
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


