import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:bucketlist/features/bucket_list/models/bucket_item.dart';
import 'package:bucketlist/features/bucket_list/repositories/bucket_list_repository.dart';
import 'package:bucketlist/features/bucket_list/providers/bucket_list_provider.dart';
import 'package:bucketlist/features/bucket_list/screens/add_item_screen.dart';

void main() {
  late BucketListRepository repository;
  late ProviderContainer container;
  late Directory testDir;

  var boxSeq = 0;

  // Hive does real async disk I/O that doesn't complete inside the
  // FakeAsync zone used by testWidgets, so we open the box with runAsync.
  setUp(() async {
    testDir = Directory.systemTemp.createTempSync();
    Hive.init(testDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(BucketItemAdapter());
    }

    boxSeq++;
    repository = BucketListRepository(boxName: 'bucket_items_$boxSeq');
    // No disk open here; deferred to each test as needed.
    container = ProviderContainer(
      overrides: [
        bucketListRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    testDir.deleteSync(recursive: true);
    // Do not close Hive here: closing inside the widget-test zone corrupts
    // the global Hive state for the following tests in this file.
  });

  Future<void> pumpAddItemScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: AddItemScreen(),
        ),
      ),
    );
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add Item'));
    await tester.tap(find.widgetWithText(FilledButton, 'Add Item'));
    await tester.pump();
  }

  Future<void> selectCategory(WidgetTester tester, String category) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(category).last);
    await tester.pumpAndSettle();
  }

  testWidgets('Empty title shows validation error', (tester) async {
    await pumpAddItemScreen(tester);

    await tapSave(tester);

    expect(find.text('Please enter an item name'), findsOneWidget);
  });

  testWidgets('Missing category shows validation error', (tester) async {
    await pumpAddItemScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Item name'),
      'Visit Goa',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Estimated price'),
      '15000',
    );

    await tapSave(tester);

    expect(find.text('Please select a category'), findsOneWidget);
  });

  testWidgets('Invalid price shows validation error', (tester) async {
    await pumpAddItemScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Item name'),
      'Visit Goa',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Estimated price'),
      'abc',
    );

    await tapSave(tester);

    expect(find.text('Please enter a valid price'), findsOneWidget);
  });

  testWidgets('Empty price shows validation error', (tester) async {
    await pumpAddItemScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Item name'),
      'Visit Goa',
    );

    await tapSave(tester);

    expect(find.text('Please enter an estimated price'), findsOneWidget);
  });

  testWidgets('Negative price shows validation error', (tester) async {
    await pumpAddItemScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Item name'),
      'Visit Goa',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Estimated price'),
      '-50',
    );

    await tapSave(tester);

    expect(find.text('Price cannot be negative'), findsOneWidget);
  });

  testWidgets('Valid form creates a BucketItem via data layer',
      (tester) async {
    await tester.runAsync(() async {
      await repository.init();
      repository.clear();
    });

    await pumpAddItemScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Item name'),
      'Visit Goa',
    );

    await selectCategory(tester, 'Travel');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Estimated price'),
      '15000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Note (optional)'),
      'Trip with friends',
    );

    await tapSave(tester);

    expect(repository.count, 1);

    final item = repository.getAll().single;
    expect(item.title, 'Visit Goa');
    expect(item.category, 'Travel');
    expect(item.estimatedPrice, 15000.0);
    expect(item.note, 'Trip with friends');
    expect(item.isCompleted, false);
    expect(item.id, isNotEmpty);

    expect(find.text('Item added successfully'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4000));
    await tester.pumpAndSettle();
  });

  testWidgets('Decimal price is stored as double', (tester) async {
    await tester.runAsync(() async {
      await repository.init();
      repository.clear();
    });

    await pumpAddItemScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Item name'),
      'Buy a camera',
    );

    await selectCategory(tester, 'Gadgets');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Estimated price'),
      '15000.50',
    );

    await tapSave(tester);

    expect(repository.count, 1);
    expect(repository.getAll().single.estimatedPrice, 15000.50);

    await tester.pump(const Duration(milliseconds: 4000));
    await tester.pumpAndSettle();
  });
}
