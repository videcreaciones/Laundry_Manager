library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:laundry_manager/data/models/garment_model.dart';
import 'package:laundry_manager/domain/services/notification_service.dart';
import 'package:laundry_manager/injection_container.dart';
import 'package:laundry_manager/presentation/providers/category_provider.dart';
import 'package:laundry_manager/presentation/providers/settings_provider.dart';
import 'package:laundry_manager/presentation/router/app_router.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
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

class LaundryManagerApp extends ConsumerStatefulWidget {
  const LaundryManagerApp({super.key});

  @override
  ConsumerState<LaundryManagerApp> createState() => _LaundryManagerAppState();
}

class _LaundryManagerAppState extends ConsumerState<LaundryManagerApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.tappedGarmentId.addListener(_onNotificationTapped);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final launchPayload = await NotificationService.consumeLaunchPayload();
      if (launchPayload != null) {
        appRouter.go(AppRoutes.detailPath(launchPayload));
      }
    });
  }

  @override
  void dispose() {
    NotificationService.tappedGarmentId.removeListener(_onNotificationTapped);
    super.dispose();
  }

  void _onNotificationTapped() {
    final id = NotificationService.tappedGarmentId.value;
    if (id != null) appRouter.go(AppRoutes.detailPath(id));
  }

  @override
  Widget build(BuildContext context) {
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
