import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:bucketlist/features/bucket_list/models/bucket_item.dart';
import 'package:bucketlist/features/bucket_list/repositories/bucket_list_repository.dart';
import 'package:bucketlist/features/bucket_list/providers/bucket_list_provider.dart';
import 'package:bucketlist/features/bucket_list/screens/bucket_list_screen.dart';
import 'package:bucketlist/theme/app_theme.dart';

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

  Future<void> initRepo(WidgetTester tester, {List<BucketItem> seed = const []}) async {
    await tester.runAsync(() async {
      await repository.init();
      repository.clear();
      for (final item in seed) {
        repository.add(item);
      }
    });
  }

  Future<void> pumpBucketList(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: BucketListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  BucketItem sampleItem({
    String id = '1',
    String title = 'Visit Goa',
    String category = 'Travel',
    double price = 15000,
    String? note = 'Trip with friends',
    bool completed = false,
    double? actualPrice,
    bool favorite = false,
    DateTime? createdAt,
  }) {
    return BucketItem(
      id: id,
      title: title,
      category: category,
      estimatedPrice: price,
      note: note,
      actualPrice: actualPrice,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      isCompleted: completed,
      isFavorite: favorite,
    );
  }

  testWidgets('Empty state appears when there are no items', (tester) async {
    await initRepo(tester);
    await pumpBucketList(tester);

    expect(find.text('Your bucket list is empty'), findsOneWidget);
    expect(find.text('Add Item'), findsWidgets);
  });

  testWidgets('Saved items appear in the list', (tester) async {
    await initRepo(tester, seed: [
      sampleItem(),
      sampleItem(id: '2', title: 'Buy a camera', category: 'Shopping', price: 40000, note: null),
    ]);
    await pumpBucketList(tester);

    expect(find.text('Visit Goa'), findsOneWidget);
    expect(find.text('Travel'), findsWidgets);
    expect(find.text('Buy a camera'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
  });

  testWidgets('Title/category/price are displayed correctly with currency', (tester) async {
    await initRepo(tester, seed: [
      sampleItem(title: 'Visit Goa', category: 'Travel', price: 15000, note: 'Trip with friends'),
    ]);
    await pumpBucketList(tester);

    expect(find.text('Visit Goa'), findsOneWidget);
    expect(find.text('Travel'), findsWidgets);
    expect(find.text('₹15,000.00'), findsWidgets);
  });

  testWidgets('Completing an item without actual price shows the price dialog', (tester) async {
    await initRepo(tester, seed: [sampleItem()]);
    await pumpBucketList(tester);

    // Tapping the item tile prompts for the actual price before completing.
    await tester.tap(find.text('Visit Goa'));
    await tester.pumpAndSettle();

    // Dialog asks for the actual price before completing.
    expect(find.text('Complete "Visit Goa"?'), findsOneWidget);
    expect(find.text('Actual price'), findsOneWidget);
    expect(repository.getAll().single.isCompleted, false);

    // Complete without entering a price.
    await tester.tap(find.text('Complete'));
    await tester.pumpAndSettle();

    expect(repository.getAll().single.isCompleted, true);
  });

  testWidgets('Completing an item with an actual price skips the dialog', (tester) async {
    await initRepo(tester, seed: [
      sampleItem(actualPrice: 12000, completed: false),
    ]);
    await pumpBucketList(tester);

    await tester.tap(find.text('Visit Goa'));
    await tester.pumpAndSettle();

    // No prompt needed; item completes immediately.
    expect(find.text('Actual price'), findsNothing);
    expect(repository.getAll().single.isCompleted, true);
    expect(repository.getAll().single.actualPrice, 12000);
  });

  testWidgets('Canceling the price dialog does not complete the item', (tester) async {
    await initRepo(tester, seed: [sampleItem()]);
    await pumpBucketList(tester);

    await tester.tap(find.text('Visit Goa'));
    await tester.pumpAndSettle();

    expect(find.text('Complete "Visit Goa"?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.getAll().single.isCompleted, false);
  });

  testWidgets('Re-toggling a completed item un-completes it without a dialog', (tester) async {
    await initRepo(tester, seed: [sampleItem(completed: true)]);
    await pumpBucketList(tester);

    // Item already completed.
    expect(repository.getAll().single.isCompleted, true);

    await tester.tap(find.text('Visit Goa'));
    await tester.pumpAndSettle();

    // No prompt, item un-completes immediately.
    expect(find.text('Actual price'), findsNothing);
    expect(repository.getAll().single.isCompleted, false);
  });

  testWidgets('Delete confirmation appears and confirmed delete removes item', (tester) async {
    await initRepo(tester, seed: [sampleItem()]);
    await pumpBucketList(tester);

    // Open the more menu and tap Delete
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Confirmation dialog appears
    expect(find.text('Delete item?'), findsOneWidget);
    expect(find.text('Are you sure you want to delete "Visit Goa"?'), findsOneWidget);

    // Confirm
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Visit Goa'), findsNothing);
    expect(repository.count, 0);
    expect(find.text('Your bucket list is empty'), findsOneWidget);
  });

  testWidgets('Cancelling delete keeps the item', (tester) async {
    await initRepo(tester, seed: [sampleItem()]);
    await pumpBucketList(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Visit Goa'), findsOneWidget);
    expect(repository.count, 1);
  });

  testWidgets('Bucket List does not show an Add FAB', (tester) async {
    await initRepo(tester);
    await pumpBucketList(tester);

    // The Add FAB lives only on the Home tab, not on the Bucket List.
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  group('Filtering', () {
    testWidgets('All categories show all items by default', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Goa trip', category: 'Travel', price: 15000),
        sampleItem(id: '2', title: 'Laptop', category: 'Gadgets', price: 60000),
        sampleItem(id: '3', title: 'Cooking class', category: 'Education', price: 5000),
      ]);
      await pumpBucketList(tester);

      expect(find.text('Goa trip'), findsOneWidget);
      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Cooking class'), findsOneWidget);
    });

    testWidgets('Selecting Travel shows only Travel items', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Goa trip', category: 'Travel', price: 15000),
        sampleItem(id: '2', title: 'Laptop', category: 'Gadgets', price: 60000),
        sampleItem(id: '3', title: 'Flight', category: 'Travel', price: 8000),
      ]);
      await pumpBucketList(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Travel'));
      await tester.pumpAndSettle();

      expect(find.text('Goa trip'), findsOneWidget);
      expect(find.text('Flight'), findsOneWidget);
      expect(find.text('Laptop'), findsNothing);
    });

    testWidgets('Selecting Gadgets shows only Gadgets items', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Goa trip', category: 'Travel', price: 15000),
        sampleItem(id: '2', title: 'Laptop', category: 'Gadgets', price: 60000),
      ]);
      await pumpBucketList(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Gadgets'));
      await tester.pumpAndSettle();

      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Goa trip'), findsNothing);
    });

    testWidgets('Empty filtered category shows empty state', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Goa trip', category: 'Travel', price: 15000),
      ]);
      await pumpBucketList(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Food'));
      await tester.pumpAndSettle();

      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(find.text('No items match this category.'), findsOneWidget);

      await tester.tap(find.text('Show all items'));
      await tester.pumpAndSettle();
      expect(find.text('Goa trip'), findsOneWidget);
    });

    testWidgets('Changing filter immediately updates the list', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Goa trip', category: 'Travel', price: 15000),
        sampleItem(id: '2', title: 'Laptop', category: 'Gadgets', price: 60000),
      ]);
      await pumpBucketList(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Travel'));
      await tester.pumpAndSettle();
      expect(find.text('Laptop'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Gadgets'));
      await tester.pumpAndSettle();
      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Goa trip'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();
      expect(find.text('Goa trip'), findsOneWidget);
      expect(find.text('Laptop'), findsOneWidget);
    });
  });

  group('Sorting', () {
    Future<void> showSortMenu(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();
    }

    Future<void> selectSort(WidgetTester tester, String label) async {
      await showSortMenu(tester);
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    double topOf(WidgetTester tester, String text) {
      return tester.getTopLeft(find.text(text).first).dy;
    }

    testWidgets('Newest first is the default order', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Old', createdAt: DateTime(2020), price: 100),
        sampleItem(id: '2', title: 'New', createdAt: DateTime(2024), price: 100),
        sampleItem(id: '3', title: 'Middle', createdAt: DateTime(2022), price: 100),
      ]);
      await pumpBucketList(tester);

      expect(topOf(tester, 'New'), lessThan(topOf(tester, 'Middle')));
      expect(topOf(tester, 'Middle'), lessThan(topOf(tester, 'Old')));
    });

    testWidgets('Oldest first orders by createdAt ascending', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Old', createdAt: DateTime(2020), price: 100),
        sampleItem(id: '2', title: 'New', createdAt: DateTime(2024), price: 100),
        sampleItem(id: '3', title: 'Middle', createdAt: DateTime(2022), price: 100),
      ]);
      await pumpBucketList(tester);

      await selectSort(tester, 'Oldest first');

      expect(topOf(tester, 'Old'), lessThan(topOf(tester, 'Middle')));
      expect(topOf(tester, 'Middle'), lessThan(topOf(tester, 'New')));
    });

    testWidgets('Price low to high', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'High', price: 90000),
        sampleItem(id: '2', title: 'Low', price: 1000),
        sampleItem(id: '3', title: 'Mid', price: 50000),
      ]);
      await pumpBucketList(tester);

      await selectSort(tester, 'Price: Low → High');

      expect(topOf(tester, 'Low'), lessThan(topOf(tester, 'Mid')));
      expect(topOf(tester, 'Mid'), lessThan(topOf(tester, 'High')));
    });

    testWidgets('Price high to low', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'High', price: 90000),
        sampleItem(id: '2', title: 'Low', price: 1000),
        sampleItem(id: '3', title: 'Mid', price: 50000),
      ]);
      await pumpBucketList(tester);

      await selectSort(tester, 'Price: High → Low');

      expect(topOf(tester, 'High'), lessThan(topOf(tester, 'Mid')));
      expect(topOf(tester, 'Mid'), lessThan(topOf(tester, 'Low')));
    });

    testWidgets('Name A to Z', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Zebra', price: 100),
        sampleItem(id: '2', title: 'Apple', price: 100),
        sampleItem(id: '3', title: 'Mango', price: 100),
      ]);
      await pumpBucketList(tester);

      await selectSort(tester, 'Name: A → Z');

      expect(topOf(tester, 'Apple'), lessThan(topOf(tester, 'Mango')));
      expect(topOf(tester, 'Mango'), lessThan(topOf(tester, 'Zebra')));
    });
  });

  group('Filtering + Sorting combined', () {
    testWidgets('Category filter combined with price sorting', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Cheap phone', category: 'Gadgets', price: 10000),
        sampleItem(id: '2', title: 'Goa trip', category: 'Travel', price: 15000),
        sampleItem(id: '3', title: 'Laptop', category: 'Gadgets', price: 80000),
        sampleItem(id: '4', title: 'Headphones', category: 'Gadgets', price: 5000),
      ]);
      await pumpBucketList(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Gadgets'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: High → Low').last);
      await tester.pumpAndSettle();

      expect(find.text('Goa trip'), findsNothing);
      final laptopY = tester.getTopLeft(find.text('Laptop').first).dy;
      final cheapY = tester.getTopLeft(find.text('Cheap phone').first).dy;
      final headphonesY = tester.getTopLeft(find.text('Headphones').first).dy;
      expect(laptopY, lessThan(cheapY));
      expect(cheapY, lessThan(headphonesY));
    });

    testWidgets('Category filter combined with name sorting', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Zoo pass', category: 'Travel', price: 400),
        sampleItem(id: '2', title: 'Apple picking', category: 'Travel', price: 300),
        sampleItem(id: '3', title: 'Laptop', category: 'Gadgets', price: 70000),
      ]);
      await pumpBucketList(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Travel'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Name: A → Z').last);
      await tester.pumpAndSettle();

      expect(find.text('Laptop'), findsNothing);
      final appleY = tester.getTopLeft(find.text('Apple picking').first).dy;
      final zooY = tester.getTopLeft(find.text('Zoo pass').first).dy;
      expect(appleY, lessThan(zooY));
    });
  });

  testWidgets('Bucket List renders without overflow on a narrow mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await initRepo(tester, seed: [
      sampleItem(id: '1', title: 'Visit Goa', category: 'Travel', price: 15000),
      sampleItem(id: '2', title: 'Buy a camera', category: 'Gadgets', price: 40000),
      sampleItem(id: '3', title: 'Learn Swimming', category: 'Health', price: 5000, completed: true),
    ]);
    await pumpBucketList(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Visit Goa'), findsOneWidget);
    expect(find.text('Buy a camera'), findsOneWidget);
    expect(find.text('Learn Swimming'), findsOneWidget);
    expect(find.text('Estimated total'), findsOneWidget);
  });

  group('Search', () {
    Future<void> openSearch(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
    }

    Future<void> typeSearch(WidgetTester tester, String query) async {
      await openSearch(tester);
      await tester.enterText(
        find.byKey(const ValueKey('search-field')),
        query,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('search field expands and filters by title', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Buy a laptop'),
        sampleItem(id: '2', title: 'Visit Goa'),
      ]);
      await pumpBucketList(tester);

      expect(find.byIcon(Icons.search), findsOneWidget);
      await typeSearch(tester, 'laptop');

      expect(find.text('Buy a laptop'), findsOneWidget);
      expect(find.text('Visit Goa'), findsNothing);
    });

    testWidgets('search is case-insensitive', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Buy a LAPTOP'),
        sampleItem(id: '2', title: 'Visit Goa'),
      ]);
      await pumpBucketList(tester);

      await typeSearch(tester, 'LaPtOp');

      expect(find.text('Buy a LAPTOP'), findsOneWidget);
      expect(find.text('Visit Goa'), findsNothing);
    });

    testWidgets('clearing search restores all items', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Buy a laptop'),
        sampleItem(id: '2', title: 'Visit Goa'),
      ]);
      await pumpBucketList(tester);

      await typeSearch(tester, 'laptop');
      expect(find.text('Visit Goa'), findsNothing);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Visit Goa'), findsOneWidget);
      expect(find.text('Buy a laptop'), findsOneWidget);
    });

    testWidgets('closing search returns to the normal AppBar', (tester) async {
      await initRepo(tester, seed: [sampleItem()]);
      await pumpBucketList(tester);

      await openSearch(tester);
      expect(find.byKey(const ValueKey('search-field')), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('search-field')), findsNothing);
      expect(find.text('Bucket List'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('empty search results show a dedicated empty state', (tester) async {
      await initRepo(tester, seed: [sampleItem(title: 'Visit Goa')]);
      await pumpBucketList(tester);

      await typeSearch(tester, 'xyznotfound');

      expect(find.text('Nothing found'), findsOneWidget);
      expect(find.text('Try a different search.'), findsOneWidget);
    });
  });

  group('Status filter', () {
    Future<void> selectStatus(WidgetTester tester, String label) async {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    testWidgets('All status shows every item by default', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Active item'),
        sampleItem(id: '2', title: 'Done item', completed: true),
      ]);
      await pumpBucketList(tester);

      expect(find.text('Active item'), findsOneWidget);
      expect(find.text('Done item'), findsOneWidget);
    });

    testWidgets('Active status shows only incomplete items', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Active item'),
        sampleItem(id: '2', title: 'Done item', completed: true),
      ]);
      await pumpBucketList(tester);

      await selectStatus(tester, 'Active');

      expect(find.text('Active item'), findsOneWidget);
      expect(find.text('Done item'), findsNothing);
    });

    testWidgets('Completed status shows only completed items', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Active item'),
        sampleItem(id: '2', title: 'Done item', completed: true),
      ]);
      await pumpBucketList(tester);

      await selectStatus(tester, 'Completed');

      expect(find.text('Done item'), findsOneWidget);
      expect(find.text('Active item'), findsNothing);
    });

    testWidgets('empty Active state shows all caught up', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Done', completed: true),
      ]);
      await pumpBucketList(tester);

      await selectStatus(tester, 'Active');

      expect(find.text('All caught up ✓'), findsOneWidget);
      expect(find.text("You've completed everything."), findsOneWidget);
    });

    testWidgets('empty Completed state shows nothing completed yet', (tester) async {
      await initRepo(tester, seed: [sampleItem(title: 'Active item')]);
      await pumpBucketList(tester);

      await selectStatus(tester, 'Completed');

      expect(find.text('Nothing completed yet'), findsOneWidget);
      expect(find.text('Time to make something happen 🚀'), findsOneWidget);
    });
  });

  group('Favorites', () {
    Future<void> enableFavorites(WidgetTester tester) async {
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
    }

    testWidgets('favorite/unfavorite from Bucket List updates state immediately', (tester) async {
      await initRepo(tester, seed: [sampleItem()]);
      await pumpBucketList(tester);

      final star = find.byKey(const ValueKey('favorite-1'));
      expect(
        find.descendant(of: star, matching: find.byIcon(Icons.star_border)),
        findsOneWidget,
      );
      expect(repository.getAll().single.isFavorite, false);

      await tester.tap(star);
      await tester.pumpAndSettle();

      expect(repository.getAll().single.isFavorite, true);
      expect(
        find.descendant(of: star, matching: find.byIcon(Icons.star)),
        findsOneWidget,
      );

      await tester.tap(star);
      await tester.pumpAndSettle();

      expect(repository.getAll().single.isFavorite, false);
      expect(
        find.descendant(of: star, matching: find.byIcon(Icons.star_border)),
        findsOneWidget,
      );
    });

    testWidgets('Favorites filter shows only favorite items', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Goa trip', favorite: true),
        sampleItem(id: '2', title: 'Laptop'),
      ]);
      await pumpBucketList(tester);

      await enableFavorites(tester);

      expect(find.text('Goa trip'), findsOneWidget);
      expect(find.text('Laptop'), findsNothing);
    });

    testWidgets('favorites default to All filter showing everything', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Goa trip', favorite: true),
        sampleItem(id: '2', title: 'Laptop'),
      ]);
      await pumpBucketList(tester);

      expect(find.text('Goa trip'), findsOneWidget);
      expect(find.text('Laptop'), findsOneWidget);
    });

    testWidgets('Favorites + Active combination', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Goa trip', favorite: true),
        sampleItem(id: '2', title: 'Laptop', favorite: true, completed: true),
        sampleItem(id: '3', title: 'Camera'),
      ]);
      await pumpBucketList(tester);

      await enableFavorites(tester);
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();

      expect(find.text('Goa trip'), findsOneWidget);
      expect(find.text('Laptop'), findsNothing);
      expect(find.text('Camera'), findsNothing);
    });

    testWidgets('Favorites + Completed combination', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Goa trip', favorite: true),
        sampleItem(id: '2', title: 'Laptop', favorite: true, completed: true),
        sampleItem(id: '3', title: 'Camera'),
      ]);
      await pumpBucketList(tester);

      await enableFavorites(tester);
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Goa trip'), findsNothing);
      expect(find.text('Camera'), findsNothing);
    });

    testWidgets('Favorites + Category combination', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Goa trip', category: 'Travel', favorite: true),
        sampleItem(id: '2', title: 'Laptop', category: 'Gadgets', favorite: true),
        sampleItem(id: '3', title: 'Camera', category: 'Gadgets'),
      ]);
      await pumpBucketList(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Gadgets'));
      await tester.pumpAndSettle();
      await enableFavorites(tester);

      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Goa trip'), findsNothing);
      expect(find.text('Camera'), findsNothing);
    });

    testWidgets('Favorites + Search combination', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Laptop Pro', favorite: true),
        sampleItem(id: '2', title: 'Laptop Air'),
        sampleItem(id: '3', title: 'Mouse', favorite: true),
      ]);
      await pumpBucketList(tester);

      await enableFavorites(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('search-field')),
        'laptop',
      );
      await tester.pumpAndSettle();

      expect(find.text('Laptop Pro'), findsOneWidget);
      expect(find.text('Laptop Air'), findsNothing);
      expect(find.text('Mouse'), findsNothing);
    });

    testWidgets('Favorites + Sorting combination', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Cheap', price: 1000, favorite: true),
        sampleItem(id: '2', title: 'Expensive', price: 90000, favorite: true),
        sampleItem(id: '3', title: 'Mid', price: 50000, favorite: true),
        sampleItem(id: '4', title: 'Ignored', price: 999999),
      ]);
      await pumpBucketList(tester);

      await enableFavorites(tester);

      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: High → Low').last);
      await tester.pumpAndSettle();

      expect(find.text('Ignored'), findsNothing);
      final expensiveY = tester.getTopLeft(find.text('Expensive').first).dy;
      final midY = tester.getTopLeft(find.text('Mid').first).dy;
      final cheapY = tester.getTopLeft(find.text('Cheap').first).dy;
      expect(expensiveY, lessThan(midY));
      expect(midY, lessThan(cheapY));
    });

    testWidgets('search + status + category + favorites + sorting combination', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Laptop Pro', category: 'Gadgets', price: 80000, favorite: true),
        sampleItem(id: '2', title: 'Laptop Air', category: 'Gadgets', price: 60000, favorite: true, completed: true),
        sampleItem(id: '3', title: 'Laptop Charger', category: 'Gadgets', price: 2000, favorite: true),
        sampleItem(id: '4', title: 'Premium Laptop', category: 'Travel', price: 90000, favorite: true),
        sampleItem(id: '5', title: 'Laptop Stand', category: 'Gadgets', price: 5000),
      ]);
      await pumpBucketList(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Gadgets'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: High → Low').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('search-field')),
        'laptop',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();

      await enableFavorites(tester);

      expect(find.text('Laptop Air'), findsNothing); // completed
      expect(find.text('Premium Laptop'), findsNothing); // wrong category
      expect(find.text('Laptop Stand'), findsNothing); // not favorite
      final proY = tester.getTopLeft(find.text('Laptop Pro').first).dy;
      final chargerY = tester.getTopLeft(find.text('Laptop Charger').first).dy;
      expect(proY, lessThan(chargerY));
    });

    testWidgets('empty Favorites state shows a dedicated message', (tester) async {
      await initRepo(tester, seed: [sampleItem()]);
      await pumpBucketList(tester);

      await enableFavorites(tester);

      expect(find.text('No favorites yet'), findsOneWidget);
      expect(find.text('Tap the star on any item to keep it close.'), findsOneWidget);
    });

    testWidgets('completing a favorite keeps it favorite', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Goa trip', favorite: true),
      ]);
      await pumpBucketList(tester);

      // Complete via the item tile (prompts for actual price; leave empty).
      await tester.tap(find.text('Goa trip'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();

      final item = repository.getAll().single;
      expect(item.isCompleted, true);
      expect(item.isFavorite, true);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('favorite-1')),
          matching: find.byIcon(Icons.star),
        ),
        findsOneWidget,
      );
    });
  });

  group('Combined filters', () {
    Future<void> openSearch(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
    }

    testWidgets('category + status combination', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Laptop', category: 'Gadgets'),
        sampleItem(id: '2', title: 'Goa', category: 'Travel', completed: true),
        sampleItem(id: '3', title: 'Mouse', category: 'Gadgets', completed: true),
      ]);
      await pumpBucketList(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Gadgets'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('Mouse'), findsOneWidget);
      expect(find.text('Laptop'), findsNothing);
      expect(find.text('Goa'), findsNothing);
    });

    testWidgets('search + category combination', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Laptop', category: 'Gadgets'),
        sampleItem(id: '2', title: 'Laptop stand', category: 'Travel'),
        sampleItem(id: '3', title: 'Mouse', category: 'Gadgets'),
      ]);
      await pumpBucketList(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Gadgets'));
      await tester.pumpAndSettle();

      await openSearch(tester);
      await tester.enterText(
        find.byKey(const ValueKey('search-field')),
        'laptop',
      );
      await tester.pumpAndSettle();

      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('Laptop stand'), findsNothing);
      expect(find.text('Mouse'), findsNothing);
    });

    testWidgets('search + status + category + sorting combination', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Laptop Pro', category: 'Gadgets', price: 80000),
        sampleItem(id: '2', title: 'Laptop Air', category: 'Gadgets', price: 60000, completed: true),
        sampleItem(id: '3', title: 'Laptop Charger', category: 'Gadgets', price: 2000),
        sampleItem(id: '4', title: 'Premium Laptop', category: 'Travel', price: 90000),
      ]);
      await pumpBucketList(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Gadgets'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: High → Low').last);
      await tester.pumpAndSettle();

      await openSearch(tester);
      await tester.enterText(
        find.byKey(const ValueKey('search-field')),
        'laptop',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();

      expect(find.text('Laptop Air'), findsNothing);
      expect(find.text('Premium Laptop'), findsNothing);
      final proY = tester.getTopLeft(find.text('Laptop Pro').first).dy;
      final chargerY = tester.getTopLeft(find.text('Laptop Charger').first).dy;
      expect(proY, lessThan(chargerY));
    });
  });

  group('Theme and narrow layout compatibility', () {
    testWidgets('renders without overflow in light and dark at 320/360/390', (tester) async {
      await initRepo(tester, seed: [
        sampleItem(id: '1', title: 'Visit Goa', category: 'Travel', price: 15000, note: 'Trip', favorite: true),
        sampleItem(id: '2', title: 'Buy a Mirrorless Camera', category: 'Gadgets', price: 40000, note: null),
        sampleItem(id: '3', title: 'Learn Swimming', category: 'Health', price: 5000, completed: true),
        sampleItem(id: '4', title: 'Cook Pasta', category: 'Food', price: 800, note: null, favorite: true),
      ]);

      for (final size in const [Size(320, 640), Size(360, 690), Size(390, 720)]) {
        for (final themeMode in const [ThemeMode.light, ThemeMode.dark]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,
                home: BucketListScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull,
              reason: 'Overflow at $size in $themeMode');
          expect(find.text('Visit Goa'), findsOneWidget);

          // Favorites filter with starred rows must not overflow either.
          await tester.tap(find.text('Favorites'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'Favorites filter overflow at $size in $themeMode');
          expect(find.text('Visit Goa'), findsOneWidget);
        }
      }
    });
  });
}
