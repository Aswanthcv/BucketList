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

  var boxSeq = 0;

  setUp(() async {
    testDir = Directory.systemTemp.createTempSync();
    Hive.init(testDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(BucketItemAdapter());
    }
    boxSeq++;
    repository = BucketListRepository(boxName: 'bucket_items_$boxSeq');
    await repository.init();
    repository.clear();
  });

  tearDown(() {
    testDir.deleteSync(recursive: true);
  });

  BucketItem item({
    String id = '1',
    String title = 'Item',
    String category = 'Travel',
    double price = 0,
    double? actual,
    bool completed = false,
    bool favorite = false,
  }) {
    return BucketItem(
      id: id,
      title: title,
      category: category,
      estimatedPrice: price,
      actualPrice: actual,
      note: null,
      createdAt: DateTime(2024, 1, int.tryParse(id) ?? 1),
      isCompleted: completed,
      isFavorite: favorite,
    );
  }

  Widget app(ThemeMode themeMode) {
    return ProviderScope(
      overrides: [
        bucketListRepositoryProvider.overrideWithValue(repository),
        themeSettingsProvider
            .overrideWithValue(ThemeSettings.inMemory(themeMode)),
        tutorialSettingsProvider
            .overrideWithValue(TutorialSettings.inMemory()),
      ],
      child: const BucketListApp(),
    );
  }

  testWidgets('App renders clean dashboard header', (tester) async {
    await tester.pumpWidget(app(ThemeMode.light));
    await tester.pumpAndSettle();

    expect(find.text('BucketList'), findsOneWidget);
    expect(find.text('Your list is empty.'), findsOneWidget);
    expect(find.text('Your bucket list is empty'), findsOneWidget);

    expect(find.text('My Bucket List'), findsNothing);
    expect(find.text('Your Bucket List'), findsNothing);
    expect(find.text('Good morning'), findsNothing);
    expect(find.text('Good afternoon'), findsNothing);
    expect(find.text('Good evening'), findsNothing);

    expect(find.text('Add'), findsWidgets);
  });

  testWidgets('Header uses actual item and completion counts', (tester) async {
    repository.add(item(id: '1', title: 'Visit Goa', price: 15000));
    repository.add(item(id: '2', title: 'Buy Camera', price: 40000));
    repository.add(
      item(id: '3', title: 'Learn Swimming', price: 5000, completed: true),
    );

    await tester.pumpWidget(app(ThemeMode.light));
    await tester.pumpAndSettle();

    expect(find.text('BucketList'), findsOneWidget);
    expect(find.text('2 things to make happen.'), findsOneWidget);
    expect(find.text('1 already done ✓'), findsOneWidget);
  });

  testWidgets('Theme switches Light → Dark → Light immediately', (tester) async {
    await tester.pumpWidget(app(ThemeMode.light));
    await tester.pumpAndSettle();

    MaterialApp materialApp() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp().themeMode, ThemeMode.light);

    // Open the appearance menu and switch to Dark.
    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(materialApp().themeMode, ThemeMode.dark);

    final darkContext =
        tester.element(find.byType(SafeArea).first);
    expect(Theme.of(darkContext).brightness, Brightness.dark);

    // Switch back to Light.
    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(materialApp().themeMode, ThemeMode.light);

    final lightContext =
        tester.element(find.byType(SafeArea).first);
    expect(Theme.of(lightContext).brightness, Brightness.light);
  });

  testWidgets('App renders without overflow at 320/360/390 in both themes',
      (tester) async {
    repository.add(
      item(id: '1', title: 'Visit Goa', category: 'Travel', price: 15000, favorite: true),
    );
    repository.add(
      item(id: '2', title: 'Buy Mirrorless Camera', category: 'Gadgets', price: 40000),
    );
    repository.add(
      item(
        id: '3',
        title: 'Learn Swimming',
        category: 'Education',
        price: 5000,
        completed: true,
        actual: 4800,
        favorite: true,
      ),
    );
    repository.add(
      item(id: '4', title: 'Cook Pasta', category: 'Food', price: 800),
    );

    for (final size in const [Size(320, 640), Size(360, 690), Size(390, 720)]) {
      for (final themeMode in const [ThemeMode.light, ThemeMode.dark]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(app(themeMode));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'Overflow at $size in $themeMode');
        expect(find.text('BucketList'), findsOneWidget);
      }
    }
  });
}