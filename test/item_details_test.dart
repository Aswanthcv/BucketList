import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:bucketlist/features/bucket_list/models/bucket_item.dart';
import 'package:bucketlist/features/bucket_list/repositories/bucket_list_repository.dart';
import 'package:bucketlist/features/bucket_list/providers/bucket_list_provider.dart';
import 'package:bucketlist/features/bucket_list/screens/item_details_screen.dart';
import 'package:bucketlist/features/bucket_list/screens/edit_item_screen.dart';
import 'package:bucketlist/features/bucket_list/screens/dashboard_screen.dart';

void main() {
  late BucketListRepository repository;
  late ProviderContainer container;
  late Directory testDir;

  var boxSeq = 0;

  setUp(() async {
    testDir = Directory.systemTemp.createTempSync();
    Hive.init(testDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(BucketItemAdapter());
    }
    boxSeq++;
    repository = BucketListRepository(boxName: 'bucket_items_$boxSeq');
    container = ProviderContainer(
      overrides: [
        bucketListRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    testDir.deleteSync(recursive: true);
  });

  Future<void> initRepo(WidgetTester tester, {BucketItem? seed}) async {
    await tester.runAsync(() async {
      await repository.init();
      repository.clear();
      if (seed != null) {
        repository.add(seed);
      }
    });
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  BucketItem sampleItem() {
    return BucketItem(
      id: 'item-1',
      title: 'Visit Goa',
      category: 'Travel',
      estimatedPrice: 15000,
      note: 'Trip with friends',
      createdAt: DateTime(2026, 9, 4),
      isCompleted: false,
    );
  }

  Future<void> tapDelete(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Delete'));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
  }

  group('Item Details', () {
    testWidgets('Item details display correctly', (tester) async {
      await initRepo(tester, seed: sampleItem());
      await pump(tester, ItemDetailsScreen(itemId: 'item-1'));

      expect(find.text('Visit Goa'), findsOneWidget);
      expect(find.text('Travel'), findsWidgets);
      expect(find.text('₹15,000.00'), findsWidgets);
      expect(find.text('Trip with friends'), findsOneWidget);
      expect(find.text('Not completed'), findsWidgets);
      expect(find.text('Added on'), findsOneWidget);
      expect(find.text('September 4, 2026'), findsOneWidget);
    });

    testWidgets('Completion status displays and can be toggled', (tester) async {
      await initRepo(tester, seed: sampleItem());
      await pump(tester, ItemDetailsScreen(itemId: 'item-1'));

      expect(find.text('Not completed'), findsWidgets);
      expect(find.text('Mark as Completed'), findsOneWidget);

      // Completing opens the actual-price dialog.
      await tester.tap(find.text('Mark as Completed'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Complete "Visit Goa"?'), findsOneWidget);
      expect(find.text('Estimated price'), findsOneWidget);

      // Complete without recording an actual price.
      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Completed'), findsWidgets);
      expect(repository.getAll().single.isCompleted, true);
      expect(repository.getAll().single.actualPrice, null);
    });

    testWidgets('Completing with an actual price records it', (tester) async {
      await initRepo(tester, seed: sampleItem());
      await pump(tester, ItemDetailsScreen(itemId: 'item-1'));

      await tester.tap(find.text('Mark as Completed'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Actual price'),
        '12000',
      );
      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();

      final item = repository.getAll().single;
      expect(item.isCompleted, true);
      expect(item.actualPrice, 12000.0);
    });

    testWidgets('Favorite can be toggled from the AppBar', (tester) async {
      await initRepo(tester, seed: sampleItem());
      await pump(tester, ItemDetailsScreen(itemId: 'item-1'));

      expect(find.text('Not favorite'), findsOneWidget);

      final star = find.byKey(const ValueKey('favorite-item-1'));
      await tester.tap(star);
      await tester.pumpAndSettle();

      expect(repository.getAll().single.isFavorite, true);
      expect(find.text('★ Favorite'), findsOneWidget);
      expect(
        find.descendant(of: star, matching: find.byIcon(Icons.star)),
        findsOneWidget,
      );

      await tester.tap(star);
      await tester.pumpAndSettle();

      expect(repository.getAll().single.isFavorite, false);
      expect(find.text('Not favorite'), findsOneWidget);
      expect(
        find.descendant(of: star, matching: find.byIcon(Icons.star_border)),
        findsOneWidget,
      );
    });

    testWidgets('Favorite state displays in the AppBar and info card', (tester) async {
      await initRepo(
        tester,
        seed: sampleItem().copyWith(isFavorite: true),
      );
      await pump(tester, ItemDetailsScreen(itemId: 'item-1'));

      expect(find.text('★ Favorite'), findsOneWidget);
      expect(find.text('Not favorite'), findsNothing);
    });

    testWidgets('Delete confirmation appears', (tester) async {
      await initRepo(tester, seed: sampleItem());
      await pump(tester, ItemDetailsScreen(itemId: 'item-1'));

      await tapDelete(tester);

      expect(find.text('Delete item?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete "Visit Goa"?'),
        findsOneWidget,
      );
    });

    testWidgets('Confirming delete removes the item', (tester) async {
      await initRepo(tester, seed: sampleItem());
      await pump(tester, ItemDetailsScreen(itemId: 'item-1'));

      await tapDelete(tester);
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(repository.count, 0);
    });
  });

  group('Edit Item', () {
    testWidgets('Existing values are pre-filled', (tester) async {
      await initRepo(tester, seed: sampleItem());
      final item = repository.getAll().single;
      await pump(tester, EditItemScreen(item: item));

      expect(find.text('Visit Goa'), findsWidgets);
      expect(find.text('15000'), findsWidgets);
      expect(find.text('Trip with friends'), findsWidgets);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('Empty title validation works', (tester) async {
      await initRepo(tester, seed: sampleItem());
      final item = repository.getAll().single;
      await pump(tester, EditItemScreen(item: item));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Item name'),
        '',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
      await tester.pump();

      expect(find.text('Please enter an item name'), findsOneWidget);
    });

    testWidgets('Invalid price validation works', (tester) async {
      await initRepo(tester, seed: sampleItem());
      final item = repository.getAll().single;
      await pump(tester, EditItemScreen(item: item));

      await tester.enterText(
        find.widgetWithText(TextFormField, '15000'),
        'abc',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
      await tester.pump();

      expect(find.text('Please enter a valid price'), findsOneWidget);
    });

    testWidgets('Negative price validation works', (tester) async {
      await initRepo(tester, seed: sampleItem());
      final item = repository.getAll().single;
      await pump(tester, EditItemScreen(item: item));

      await tester.enterText(
        find.widgetWithText(TextFormField, '15000'),
        '-10',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
      await tester.pump();

      expect(find.text('Price cannot be negative'), findsOneWidget);
    });

    testWidgets('Saving valid changes updates the item and preserves identity', (tester) async {
      await initRepo(tester, seed: sampleItem());
      final original = repository.getAll().single;
      await pump(tester, EditItemScreen(item: original));

      await tester.enterText(
        find.widgetWithText(TextFormField, '15000'),
        '20000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Trip with friends'),
        'Trip with friends in December',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
      await tester.pump();

      final updated = repository.getAll().single;
      expect(updated.estimatedPrice, 20000);
      expect(updated.note, 'Trip with friends in December');
      expect(updated.id, original.id);
      expect(updated.createdAt, original.createdAt);
      expect(updated.isCompleted, original.isCompleted);
    });

    testWidgets('Updated price changes dashboard total', (tester) async {
      await initRepo(tester, seed: sampleItem());
      await openEditThroughNavigation(tester, container);

      await tester.enterText(
        find.widgetWithText(TextFormField, '15000'),
        '20000',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
      await tester.pumpAndSettle();

      // Back on Bucket List, confirming the edit persisted.
      expect(find.text('Visit Goa'), findsOneWidget);
      expect(find.text('₹20,000.00'), findsWidgets);

      // Pop back to the Dashboard and confirm the total reflects the edit.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(find.text('₹20,000.00'), findsWidgets);
    });

    testWidgets('Updated item appears with new values in Bucket List', (tester) async {
      await initRepo(tester, seed: sampleItem());
      await openEditThroughNavigation(tester, container);

      await tester.enterText(
        find.widgetWithText(TextFormField, '15000'),
        '20000',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
      await tester.pumpAndSettle();

      // Back on Bucket List, confirming the edit persisted.
      expect(find.text('Visit Goa'), findsOneWidget);
      expect(find.text('₹20,000.00'), findsWidgets);
    });

    testWidgets('Deleted/nonexistent item is handled safely', (tester) async {
      await initRepo(tester, seed: sampleItem());
      await pump(tester, ItemDetailsScreen(itemId: 'missing-id'));

      expect(find.text('This item no longer exists.'), findsOneWidget);
    });
  });
}

/// Navigates Dashboard -> Bucket List -> Edit Item through the real widget
/// navigation stack, landing on the Edit Item screen (via the edit button).
Future<void> openEditThroughNavigation(
  WidgetTester tester,
  ProviderContainer container,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );
  await tester.pumpAndSettle();

  // Dashboard -> Bucket List
  await tester.tap(find.text('View all'));
  await tester.pumpAndSettle();

  // Bucket List -> Edit Item (edit button next to the item name).
  await tester.tap(find.byKey(const ValueKey('edit-item-1')));
  await tester.pumpAndSettle();
}
