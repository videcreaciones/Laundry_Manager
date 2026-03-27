library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String kSettingsBoxName = 'settings';
const String _kDarkMode       = 'dark_mode';
const String _kAutoFill       = 'auto_fill';

class SettingsNotifier extends Notifier<AppSettings> {
  late Box _box;

  @override
  AppSettings build() {
    _box = Hive.box(kSettingsBoxName);
    return AppSettings(
      darkMode: _box.get(_kDarkMode, defaultValue: false) as bool,
      autoFill: _box.get(_kAutoFill, defaultValue: false) as bool,
    );
  }

  void toggleDarkMode() {
    final updated = state.copyWith(darkMode: !state.darkMode);
    _box.put(_kDarkMode, updated.darkMode);
    state = updated;
  }

  void toggleAutoFill() {
    final updated = state.copyWith(autoFill: !state.autoFill);
    _box.put(_kAutoFill, updated.autoFill);
    state = updated;
  }
}

class AppSettings {
  final bool darkMode;
  final bool autoFill;

  const AppSettings({required this.darkMode, required this.autoFill});

  AppSettings copyWith({bool? darkMode, bool? autoFill}) => AppSettings(
    darkMode: darkMode ?? this.darkMode,
    autoFill: autoFill ?? this.autoFill,
  );
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
