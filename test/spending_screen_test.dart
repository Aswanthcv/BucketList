import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:bucketlist/features/bucket_list/models/bucket_item.dart';
import 'package:bucketlist/features/bucket_list/repositories/bucket_list_repository.dart';
import 'package:bucketlist/features/bucket_list/providers/bucket_list_provider.dart';
import 'package:bucketlist/features/bucket_list/providers/bucket_stats_provider.dart';
import 'package:bucketlist/features/bucket_list/screens/spending_screen.dart';

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

  Future<void> pumpSpending(WidgetTester tester, {Size size = const Size(800, 2000)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SpendingScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  BucketItem item({
    String id = '1',
    String category = 'Travel',
    double price = 3000,
    double? actual,
    bool completed = false,
    DateTime? createdAt,
  }) {
    return BucketItem(
      id: id,
      title: 'Item $id',
      category: category,
      estimatedPrice: price,
      actualPrice: actual,
      createdAt: createdAt ?? DateTime(2024, 1, int.parse(id)),
      isCompleted: completed,
    );
  }

  testWidgets('Spending shows total and purchase count', (tester) async {
    await initRepo(tester, seed: [
      item(id: '1', category: 'Gadgets', price: 3000, actual: 2750, completed: true),
      item(id: '2', category: 'Travel', price: 8000, actual: 8000, completed: true),
    ]);
    await pumpSpending(tester);

    expect(find.text('Spending'), findsOneWidget);
    expect(find.text('Actually spent'), findsOneWidget);
    expect(find.text('₹10,750.00'), findsOneWidget);
    expect(find.text('2 purchases'), findsOneWidget);
  });

  testWidgets('Incomplete items and items without actual price are excluded', (tester) async {
    await initRepo(tester, seed: [
      item(id: '1', category: 'Gadgets', price: 3000, actual: 2750, completed: true),
      item(id: '2', category: 'Travel', price: 8000, completed: true),
      item(id: '3', category: 'Food', price: 5000, actual: 4500),
    ]);
    await pumpSpending(tester);

    expect(find.text('₹2,750.00'), findsWidgets);
    expect(find.text('1 purchase'), findsOneWidget);
    expect(find.text('Item 2'), findsNothing);
    expect(find.text('Item 3'), findsNothing);
  });

  testWidgets('Spending groups amounts by category', (tester) async {
    await initRepo(tester, seed: [
      item(id: '1', category: 'Gadgets', price: 3000, actual: 2750, completed: true),
      item(id: '2', category: 'Gadgets', price: 1000, actual: 1000, completed: true),
      item(id: '3', category: 'Travel', price: 8000, actual: 7900, completed: true),
    ]);
    await pumpSpending(tester);

    expect(find.text('By category'), findsOneWidget);
    expect(find.text('Gadgets'), findsWidgets);
    expect(find.text('Travel'), findsWidgets);
    expect(find.text('₹3,750.00'), findsOneWidget);
    expect(find.text('₹7,900.00'), findsWidgets);
  });

  testWidgets('Spending shows empty state when nothing recorded', (tester) async {
    await initRepo(tester, seed: [
      item(id: '1', category: 'Travel', price: 8000, completed: true),
      item(id: '2', category: 'Food', price: 5000),
    ]);
    await pumpSpending(tester);

    expect(find.text('No spending yet'), findsOneWidget);
    expect(find.textContaining('Complete something from'), findsOneWidget);
  });

  testWidgets('Spending renders without overflow on a narrow viewport', (tester) async {
    await initRepo(tester, seed: [
      item(id: '1', category: 'Gadgets', price: 30000, actual: 27500, completed: true),
      item(id: '2', category: 'Travel', price: 80000, actual: 78950, completed: true),
      item(id: '3', category: 'Education', price: 5000, actual: 4800, completed: true),
    ]);
    await pumpSpending(tester, size: const Size(320, 640));

    expect(tester.takeException(), isNull);
    expect(find.text('Actually spent'), findsOneWidget);
    expect(find.text('3 purchases'), findsOneWidget);
  });

  testWidgets('Stats provider exposes spending totals reactively', (tester) async {
    await initRepo(tester, seed: [
      item(id: '1', category: 'Gadgets', price: 3000, actual: 2750, completed: true),
    ]);
    await pumpSpending(tester);

    final stats = container.read(spendingStatsProvider);
    expect(stats.totalSpent, 2750);
    expect(stats.purchaseCount, 1);
    expect(stats.byCategory['Gadgets'], 2750);
  });
}