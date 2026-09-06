import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:bucketlist/features/bucket_list/models/bucket_item.dart';
import 'package:bucketlist/features/bucket_list/repositories/bucket_list_repository.dart';
import 'package:bucketlist/features/bucket_list/providers/bucket_list_provider.dart';
import 'package:bucketlist/features/bucket_list/providers/bucket_stats_provider.dart';
import 'package:bucketlist/features/bucket_list/screens/dashboard_screen.dart';
import 'package:bucketlist/features/bucket_list/screens/bucket_list_screen.dart';

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

  Future<void> pumpDashboard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
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

  BucketItem item({
    int id = 0,
    String title = 'Item',
    double price = 0,
    bool completed = false,
    bool favorite = false,
  }) {
    return BucketItem(
      id: '$id',
      title: title,
      category: 'Travel',
      estimatedPrice: price,
      note: null,
      createdAt: DateTime(2024, 1, id + 1),
      isCompleted: completed,
      isFavorite: favorite,
    );
  }

  final seedItems = [
    item(id: 1, title: 'Visit Goa', price: 15000),
    item(id: 2, title: 'Buy Camera', price: 40000),
    item(id: 3, title: 'Learn Swimming', price: 5000, completed: true),
  ];

  testWidgets('Dashboard displays total cost and item counts', (tester) async {
    await initRepo(tester, seed: seedItems);
    await pumpDashboard(tester);

    // Clean header with dynamic subtitle from item counts.
    expect(find.text('BucketList'), findsOneWidget);
    expect(find.text('2 things to make happen.'), findsOneWidget);
    expect(find.text('1 already done ✓'), findsOneWidget);

    // Total cost ₹60,000.00 shown in the cost summary.
    expect(find.text('₹60,000.00'), findsWidgets);

    // Item counts in the progress summary.
    expect(find.text('1 of 3 done'), findsOneWidget);
    expect(find.text('2 remaining'), findsOneWidget);
  });

  testWidgets('Dashboard displays completion progress', (tester) async {
    await initRepo(tester, seed: seedItems);
    await pumpDashboard(tester);

    expect(find.text('33%'), findsOneWidget);

    // LinearProgressIndicator with value 1/3
    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator).first,
    );
    expect(progress.value, closeTo(1 / 3, 0.001));
  });

  testWidgets('Dashboard displays cost breakdown', (tester) async {
    await initRepo(tester, seed: seedItems);
    await pumpDashboard(tester);

    expect(find.text('Estimated cost'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Actually spent'), findsWidgets);
    expect(find.text('Remaining'), findsWidgets);
    expect(find.text('₹60,000.00'), findsWidgets);
    expect(find.text('₹55,000.00'), findsOneWidget);
  });

  testWidgets('Dashboard shows empty state when no items', (tester) async {
    await initRepo(tester);
    await pumpDashboard(tester);

    expect(find.text('Your bucket list is empty'), findsWidgets);
    expect(find.text('Add Item'), findsWidgets);
  });

  testWidgets('Bucket List displays total cost in the bottom summary', (tester) async {
    await initRepo(tester, seed: seedItems);
    await pumpBucketList(tester);

    expect(find.text('3 things to do'), findsOneWidget);
    expect(find.text('Estimated total'), findsOneWidget);
    expect(find.text('₹60,000.00'), findsWidgets);
    expect(find.text('2 remaining • 1 completed'), findsOneWidget);
  });

  testWidgets('Completing an item updates statistics', (tester) async {
    await initRepo(tester, seed: seedItems);
    await pumpBucketList(tester);

    expect(find.text('3 things to do'), findsOneWidget);

    // Complete the newest incomplete item (Buy Camera, newest first).
    // Without an actual price a completion dialog appears; confirm it.
    await tester.tap(find.byKey(const ValueKey('toggle-2')));
    await tester.pumpAndSettle();

    expect(find.text('Complete "Buy Camera"?'), findsOneWidget);
    await tester.tap(find.text('Complete'));
    await tester.pumpAndSettle();

    // Stats recompute reactively from the provider.
    final stats = container.read(bucketStatsProvider);
    expect(stats.totalItems, 3);
    expect(stats.completedItems, 2);
    expect(stats.remainingItems, 1);
    expect(stats.totalCost, 60000);
  });

  testWidgets('Deleting an item updates totals', (tester) async {
    await initRepo(tester, seed: seedItems);
    await pumpBucketList(tester);

    expect(find.text('3 things to do'), findsOneWidget);

    // Delete the newest item (Learn Swimming ₹5,000) via its menu.
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('2 things to do'), findsOneWidget);

    final stats = container.read(bucketStatsProvider);
    expect(stats.totalItems, 2);
    expect(stats.totalCost, 55000);
  });

  testWidgets('Priorities section shows up to three favorite active items', (tester) async {
    await initRepo(tester, seed: [
      item(id: 0, title: 'Run Marathon', price: 2000, favorite: true, completed: true),
      item(id: 1, title: 'Visit Goa', price: 15000, favorite: true),
      item(id: 2, title: 'Buy Camera', price: 40000, favorite: true),
      item(id: 3, title: 'Learn Swimming', price: 5000),
      item(id: 4, title: 'Cook Pasta', price: 800, favorite: true),
      item(id: 5, title: 'Read Books', price: 300, favorite: true),
    ]);
    await pumpDashboard(tester);

    expect(find.text('⭐ Priorities'), findsOneWidget);
    // The three newest favorite active items are shown.
    expect(find.text('Read Books'), findsWidgets);
    expect(find.text('Cook Pasta'), findsWidgets);
    expect(find.text('Buy Camera'), findsOneWidget);
    // The 4th active favorite is clipped, completed favorites are excluded.
    expect(find.text('Visit Goa'), findsNothing);
    expect(find.text('Run Marathon'), findsNothing);
  });

  testWidgets('No Priorities section when there are no favorites', (tester) async {
    await initRepo(tester, seed: seedItems);
    await pumpDashboard(tester);

    expect(find.text('⭐ Priorities'), findsNothing);
  });

  testWidgets('No Priorities section when favorites are all completed', (tester) async {
    await initRepo(tester, seed: [
      item(id: 1, title: 'Visit Goa', price: 15000, favorite: true, completed: true),
    ]);
    await pumpDashboard(tester);

    expect(find.text('⭐ Priorities'), findsNothing);
  });

  testWidgets('Unfavoriting from Home removes the item from Priorities', (tester) async {
    await initRepo(tester, seed: [
      item(id: 1, title: 'Visit Goa', price: 15000, favorite: true),
      item(id: 2, title: 'Buy Camera', price: 40000),
      item(id: 3, title: 'Learn Swimming', price: 5000),
      item(id: 4, title: 'Cook Pasta', price: 800),
      item(id: 5, title: 'Read Books', price: 300),
    ]);
    await pumpDashboard(tester);

    expect(find.text('⭐ Priorities'), findsOneWidget);
    expect(find.text('Visit Goa'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('favorite-1')));
    await tester.pumpAndSettle();

    expect(repository.getAll().firstWhere((i) => i.id == '1').isFavorite, false);
    expect(find.text('⭐ Priorities'), findsNothing);
    expect(find.text('Visit Goa'), findsNothing);
  });
}
