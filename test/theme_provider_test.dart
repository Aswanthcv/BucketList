import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:bucketlist/theme/theme_provider.dart';

void main() {
  late Directory testDir;

  setUp(() {
    testDir = Directory.systemTemp.createTempSync();
    Hive.init(testDir.path);
  });

  tearDown(() async {
    await Hive.close();
    testDir.deleteSync(recursive: true);
  });

  test('ThemeSettings persists the selected theme across restarts', () async {
    final settings = await ThemeSettings.open();
    expect(settings.mode, ThemeMode.light);

    settings.setMode(ThemeMode.dark);
    expect(settings.mode, ThemeMode.dark);

    // Simulate an app restart: a fresh instance reads the stored value.
    final reopened = await ThemeSettings.open();
    expect(reopened.mode, ThemeMode.dark);

    reopened.setMode(ThemeMode.light);
    final reopenedAgain = await ThemeSettings.open();
    expect(reopenedAgain.mode, ThemeMode.light);
  });

  test('ThemeModeNotifier updates the theme immediately', () async {
    final settings = await ThemeSettings.open();
    final container = ProviderContainer(
      overrides: [
        themeSettingsProvider.overrideWithValue(settings),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.light);

    container.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);

    // The change is persisted for the next launch.
    final reopened = await ThemeSettings.open();
    expect(reopened.mode, ThemeMode.dark);
  });

  test('App defaults to light for existing users without a stored value',
      () async {
    final settings = await ThemeSettings.open();
    expect(settings.mode, ThemeMode.light);
  });
}