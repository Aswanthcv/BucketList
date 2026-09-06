import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:bucketlist/app/app.dart';
import 'package:bucketlist/features/bucket_list/models/bucket_item.dart';
import 'package:bucketlist/features/bucket_list/repositories/bucket_list_repository.dart';
import 'package:bucketlist/features/bucket_list/providers/bucket_list_provider.dart';
import 'package:bucketlist/onboarding/tutorial_settings.dart';
import 'package:bucketlist/theme/theme_provider.dart';

void main() {
  late Directory testDir;
  late BucketListRepository repository;

  setUp(() async {
    testDir = Directory.systemTemp.createTempSync();
    Hive.init(testDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(BucketItemAdapter());
    }
    repository = BucketListRepository(boxName: 'bucket_items');
    await repository.init();
    repository.clear();
  });

  tearDown(() {
    testDir.deleteSync(recursive: true);
  });

  Widget app({required bool seen}) {
    return ProviderScope(
      overrides: [
        bucketListRepositoryProvider.overrideWithValue(repository),
        themeSettingsProvider.overrideWithValue(ThemeSettings.inMemory()),
        tutorialSettingsProvider
            .overrideWithValue(TutorialSettings.inMemory(seen)),
      ],
      child: const BucketListApp(),
    );
  }

  testWidgets('First launch shows the tutorial card', (tester) async {
    await tester.pumpWidget(app(seen: false));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to BucketList'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);

    // The app shell still renders underneath the overlay.
    expect(find.text('BucketList'), findsWidgets);
  });

  testWidgets('Tapping Got it dismisses the card', (tester) async {
    await tester.pumpWidget(app(seen: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to BucketList'), findsNothing);
    expect(find.text('Got it'), findsNothing);
  });

  testWidgets('Tutorial is not shown on subsequent launches', (tester) async {
    await tester.pumpWidget(app(seen: true));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to BucketList'), findsNothing);
  });

  testWidgets('Tutorial card renders without overflow on a narrow viewport',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(seen: false));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Welcome to BucketList'), findsOneWidget);
  });

  test('Persistence marks the tutorial as seen in the Hive box', () async {
    final settings = await TutorialSettings.open();
    expect(settings.hasSeenTutorial, false);

    settings.markSeen();

    final reloaded = await TutorialSettings.open();
    expect(reloaded.hasSeenTutorial, true);
  });
}