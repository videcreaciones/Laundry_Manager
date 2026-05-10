library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String kSettingsBoxName = 'settings';

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
      darkMode:           _box.get('dark_mode',            defaultValue: false) as bool,
      autoFill:           _box.get('auto_fill',            defaultValue: false) as bool,
      companyMode:        _box.get('company_mode',         defaultValue: false) as bool,
      singleUserName:     _box.get('single_user_name',     defaultValue: '') as String,
      autoFillOwner:      _box.get('auto_fill_owner',      defaultValue: false) as bool,
      showOwnerField:     _box.get('show_owner_field',     defaultValue: true) as bool,
      useStatusSelector:  _box.get('use_status_selector',  defaultValue: false) as bool,
      showGarmentCounter: _box.get('show_garment_counter', defaultValue: false) as bool,
    );
  }

  void _persist(AppSettings s) {
    _box.put('dark_mode',            s.darkMode);
    _box.put('auto_fill',            s.autoFill);
    _box.put('company_mode',         s.companyMode);
    _box.put('single_user_name',     s.singleUserName);
    _box.put('auto_fill_owner',      s.autoFillOwner);
    _box.put('show_owner_field',     s.showOwnerField);
    _box.put('use_status_selector',  s.useStatusSelector);
    _box.put('show_garment_counter', s.showGarmentCounter);
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
