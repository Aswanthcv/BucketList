import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class ThemeSettings {
  static const _boxName = 'app_settings';
  static const _key = 'themeMode';

  final Box<dynamic>? _box;
  ThemeMode _mode;

  ThemeSettings._(this._box, this._mode);

  static Future<ThemeSettings> open() async {
    final box = await Hive.openBox<dynamic>(_boxName);
    return ThemeSettings._(box, _modeFromStored(box.get(_key)));
  }

  factory ThemeSettings.inMemory([ThemeMode mode = ThemeMode.light]) {
    return ThemeSettings._(null, mode);
  }

  static ThemeMode _modeFromStored(Object? value) {
    if (value == _darkKey) return ThemeMode.dark;
    return ThemeMode.light;
  }

  static const String _darkKey = 'dark';

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    _mode = mode;
    _box?.put(_key, mode == ThemeMode.dark ? _darkKey : 'light');
  }
}

final themeSettingsProvider = Provider<ThemeSettings>((ref) {
  return ThemeSettings.inMemory();
});

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ref.watch(themeSettingsProvider).mode;
  }

  void setTheme(ThemeMode mode) {
    ref.read(themeSettingsProvider).setMode(mode);
    state = mode;
  }
}