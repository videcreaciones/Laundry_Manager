library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:laundry_manager/data/models/garment_model.dart';
import 'package:laundry_manager/injection_container.dart';
import 'package:laundry_manager/presentation/providers/category_provider.dart';
import 'package:laundry_manager/presentation/providers/settings_provider.dart';
import 'package:laundry_manager/presentation/router/app_router.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(GarmentModelAdapter());
  }

  late final Box<GarmentModel> garmentBox;
  try {
    garmentBox = await Hive.openBox<GarmentModel>(kGarmentBoxName);
  } catch (_) {
    await Hive.deleteBoxFromDisk(kGarmentBoxName);
    garmentBox = await Hive.openBox<GarmentModel>(kGarmentBoxName);
  }

  await Hive.openBox(kCategoryBoxName);
  await Hive.openBox(kSettingsBoxName);

  runApp(
    ProviderScope(
      overrides: [hiveBoxProvider.overrideWithValue(garmentBox)],
      child: const LaundryManagerApp(),
    ),
  );
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
      ),
      routerConfig: appRouter,
    );
  }
}
