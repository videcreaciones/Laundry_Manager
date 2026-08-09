library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String kSettingsBoxName = 'settings';
const String _kDarkMode           = 'dark_mode';
const String _kAutoFill           = 'auto_fill';
const String _kCompanyMode        = 'company_mode';
const String _kSingleUserName     = 'single_user_name';
const String _kAutoFillOwner      = 'auto_fill_owner';
const String _kShowOwnerField     = 'show_owner_field';
const String _kUseStatusSelector  = 'use_status_selector';
const String _kShowGarmentCounter = 'show_garment_counter';

class AppSettings {
  final bool darkMode;
  final bool autoFill;
  final bool companyMode;
  final String singleUserName;
  final bool autoFillOwner;
  final bool showOwnerField;
  final bool useStatusSelector;
  final bool showGarmentCounter;

  const AppSettings({
    required this.darkMode,
    required this.autoFill,
    required this.companyMode,
    required this.singleUserName,
    required this.autoFillOwner,
    required this.showOwnerField,
    required this.useStatusSelector,
    required this.showGarmentCounter,
  });

  AppSettings copyWith({
    bool? darkMode,
    bool? autoFill,
    bool? companyMode,
    String? singleUserName,
    bool? autoFillOwner,
    bool? showOwnerField,
    bool? useStatusSelector,
    bool? showGarmentCounter,
  }) => AppSettings(
    darkMode:           darkMode           ?? this.darkMode,
    autoFill:           autoFill           ?? this.autoFill,
    companyMode:        companyMode        ?? this.companyMode,
    singleUserName:     singleUserName     ?? this.singleUserName,
    autoFillOwner:      autoFillOwner      ?? this.autoFillOwner,
    showOwnerField:     showOwnerField     ?? this.showOwnerField,
    useStatusSelector:  useStatusSelector  ?? this.useStatusSelector,
    showGarmentCounter: showGarmentCounter ?? this.showGarmentCounter,
  );
}

class SettingsNotifier extends Notifier<AppSettings> {
  late Box _box;

  @override
  AppSettings build() {
    _box = Hive.box(kSettingsBoxName);
    return AppSettings(
      darkMode:           _box.get(_kDarkMode,           defaultValue: false) as bool,
      autoFill:           _box.get(_kAutoFill,           defaultValue: false) as bool,
      companyMode:        _box.get(_kCompanyMode,        defaultValue: false) as bool,
      singleUserName:     _box.get(_kSingleUserName,     defaultValue: '') as String,
      autoFillOwner:      _box.get(_kAutoFillOwner,      defaultValue: false) as bool,
      showOwnerField:     _box.get(_kShowOwnerField,     defaultValue: true) as bool,
      useStatusSelector:  _box.get(_kUseStatusSelector,  defaultValue: false) as bool,
      showGarmentCounter: _box.get(_kShowGarmentCounter, defaultValue: false) as bool,
    );
  }

  void _persist(AppSettings s) {
    _box.put(_kDarkMode,           s.darkMode);
    _box.put(_kAutoFill,           s.autoFill);
    _box.put(_kCompanyMode,        s.companyMode);
    _box.put(_kSingleUserName,     s.singleUserName);
    _box.put(_kAutoFillOwner,      s.autoFillOwner);
    _box.put(_kShowOwnerField,     s.showOwnerField);
    _box.put(_kUseStatusSelector,  s.useStatusSelector);
    _box.put(_kShowGarmentCounter, s.showGarmentCounter);
    state = s;
  }

  void toggleDarkMode()            => _persist(state.copyWith(darkMode:           !state.darkMode));
  void toggleAutoFill()            => _persist(state.copyWith(autoFill:           !state.autoFill));
  void toggleCompanyMode()         => _persist(state.copyWith(companyMode:        !state.companyMode));
  void toggleAutoFillOwner()       => _persist(state.copyWith(autoFillOwner:      !state.autoFillOwner));
  void toggleShowOwnerField()      => _persist(state.copyWith(showOwnerField:     !state.showOwnerField));
  void toggleUseStatusSelector()   => _persist(state.copyWith(useStatusSelector:  !state.useStatusSelector));
  void toggleShowGarmentCounter()  => _persist(state.copyWith(showGarmentCounter: !state.showGarmentCounter));
  void setSingleUserName(String n) => _persist(state.copyWith(singleUserName: n));
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
