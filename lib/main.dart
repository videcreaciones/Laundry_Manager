library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:laundry_manager/data/datasources/garment_image_storage.dart';
import 'package:laundry_manager/data/models/garment_model.dart';
import 'package:laundry_manager/injection_container.dart';
import 'package:laundry_manager/presentation/providers/category_provider.dart';
import 'package:laundry_manager/presentation/providers/settings_provider.dart';
import 'package:laundry_manager/presentation/router/app_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(GarmentModelAdapter());
  }

  final garmentBox = await _openGarmentBoxSafely(appDocDir.path);

  await Hive.openBox(kCategoryBoxName);
  await Hive.openBox(kSettingsBoxName);

  final imageStorage = GarmentImageStorage(
    Directory(p.join(appDocDir.path, 'garment_images')),
  );

  runApp(
    ProviderScope(
      overrides: [
        hiveBoxProvider.overrideWithValue(garmentBox),
        garmentImageStorageProvider.overrideWithValue(imageStorage),
      ],
      child: const LaundryManagerApp(),
    ),
  );
}

/// Abre la base de prendas sin perderlas si el archivo está dañado.
///
/// Hive no falla con un archivo dañado: lo recorta en silencio hasta la última
/// entrada válida, a veces a 0 bytes. Por eso se copia antes de abrirlo y, si
/// Hive lo achica o no logra abrirlo, la copia se conserva como
/// `garments.hive.danado-<fecha>` para poder recuperar las prendas.
Future<Box<GarmentModel>> _openGarmentBoxSafely(String dir) async {
  final boxFile = File(p.join(dir, '${kGarmentBoxName.toLowerCase()}.hive'));
  final copy = File('${boxFile.path}.previo');
  final sizeBefore = await boxFile.exists() ? await boxFile.length() : 0;
  if (sizeBefore > 0) {
    try {
      await boxFile.copy(copy.path);
    } on FileSystemException {
      // Sin espacio para la copia: se abre igual para no bloquear la app.
    }
  }

  Future<void> keepCopy() async {
    if (await copy.exists()) {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      await copy.rename('${boxFile.path}.danado-$stamp');
    }
  }

  try {
    final box = await Hive.openBox<GarmentModel>(kGarmentBoxName);
    if (await boxFile.length() < sizeBefore) {
      await keepCopy();
    } else if (await copy.exists()) {
      await copy.delete();
    }
    return box;
  } catch (_) {
    await keepCopy();
    await Hive.deleteBoxFromDisk(kGarmentBoxName);
    return Hive.openBox<GarmentModel>(kGarmentBoxName);
  }
}

class LaundryManagerApp extends ConsumerWidget {
  const LaundryManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: 'Laundry Manager',
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(elevation: 4),
        inputDecorationTheme: _glassInputTheme(Brightness.light),
        filledButtonTheme: _glassFilledButtonTheme,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(elevation: 4),
        inputDecorationTheme: _glassInputTheme(Brightness.dark),
        filledButtonTheme: _glassFilledButtonTheme,
      ),
      routerConfig: appRouter,
    );
  }
}

InputDecorationTheme _glassInputTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final tint = isDark ? Colors.white : Colors.black;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: tint.withValues(alpha: isDark ? 0.12 : 0.08)),
  );
  return InputDecorationTheme(
    filled: true,
    fillColor: Colors.white.withValues(alpha: isDark ? 0.06 : 0.55),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
    ),
  );
}

final FilledButtonThemeData _glassFilledButtonTheme = FilledButtonThemeData(
  style: FilledButton.styleFrom(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ),
);
