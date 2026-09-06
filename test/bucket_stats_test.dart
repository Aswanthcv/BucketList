import 'package:flutter_test/flutter_test.dart';
import 'package:bucketlist/features/bucket_list/models/bucket_item.dart';
import 'package:bucketlist/features/bucket_list/providers/bucket_stats_provider.dart';

BucketItem item({
  int id = 0,
  double price = 0,
  bool completed = false,
  bool favorite = false,
  String category = 'Travel',
  double? actual,
}) {
  return BucketItem(
    id: '$id',
    title: 'Item $id',
    category: category,
    estimatedPrice: price,
    actualPrice: actual,
    createdAt: DateTime(2024, 1, id + 1),
    isCompleted: completed,
    isFavorite: favorite,
  );
}

void main() {
  group('BucketStats', () {
    test('Zero items returns zero totals', () {
      final stats = BucketStats.fromItems([]);

      expect(stats.totalItems, 0);
      expect(stats.completedItems, 0);
      expect(stats.remainingItems, 0);
      expect(stats.totalCost, 0);
      expect(stats.completedCost, 0);
      expect(stats.remainingCost, 0);
      expect(stats.progress, 0);
    });

    test('Multiple items calculate total correctly', () {
      final stats = BucketStats.fromItems([
        item(id: 1, price: 15000),
        item(id: 2, price: 40000),
        item(id: 3, price: 5000),
      ]);

      expect(stats.totalItems, 3);
      expect(stats.totalCost, 60000);
    });

    test('Completed items are counted correctly', () {
      final stats = BucketStats.fromItems([
        item(id: 1, price: 15000, completed: true),
        item(id: 2, price: 40000),
        item(id: 3, price: 5000, completed: true),
      ]);

      expect(stats.completedItems, 2);
    });

    test('Remaining items are calculated correctly', () {
      final stats = BucketStats.fromItems([
        item(id: 1, price: 15000, completed: true),
        item(id: 2, price: 40000),
        item(id: 3, price: 5000),
      ]);

      expect(stats.remainingItems, 2);
    });

    test('Favorite items are counted correctly', () {
      final stats = BucketStats.fromItems([
        item(id: 1, price: 15000, favorite: true),
        item(id: 2, price: 40000, favorite: true),
        item(id: 3, price: 5000),
        item(id: 4, price: 800, favorite: true),
      ]);

      expect(stats.favoriteItems, 3);
    });

    test('Completed cost is calculated correctly', () {
      final stats = BucketStats.fromItems([
        item(id: 1, price: 15000, completed: true),
        item(id: 2, price: 40000),
        item(id: 3, price: 5000, completed: true),
      ]);

      expect(stats.completedCost, 20000);
    });

    test('Remaining cost is calculated correctly', () {
      final stats = BucketStats.fromItems([
        item(id: 1, price: 15000, completed: true),
        item(id: 2, price: 40000),
        item(id: 3, price: 5000, completed: true),
      ]);

      expect(stats.remainingCost, 40000);
    });

    test('Decimal prices calculate correctly', () {
      final stats = BucketStats.fromItems([
        item(id: 1, price: 15000.50, completed: true),
        item(id: 2, price: 40000.25),
      ]);

      expect(stats.totalCost, 55000.75);
      expect(stats.completedCost, 15000.50);
      expect(stats.remainingCost, 40000.25);
    });

    test('Progress is a fraction and handles zero items', () {
      expect(BucketStats.fromItems([]).progress, 0);

      final half = BucketStats.fromItems([
        item(id: 1, price: 1, completed: true),
        item(id: 2, price: 1),
      ]);
      expect(half.progress, 0.5);

      final all = BucketStats.fromItems([
        item(id: 1, price: 1, completed: true),
        item(id: 2, price: 1, completed: true),
      ]);
      expect(all.progress, 1.0);
    });
  });

  group('BucketStats actual spending fields', () {
    test('actualSpentTotal sums actual price of completed items only', () {
      final stats = BucketStats.fromItems([
        item(id: 1, price: 15000, completed: true, actual: 14000),
        item(id: 2, price: 40000, completed: true, actual: 41000),
        item(id: 3, price: 5000, completed: true),
        item(id: 4, price: 8000),
      ]);

      expect(stats.actualSpentTotal, 55000);
      expect(stats.actualCount, 2);
    });

    test('actualSpentTotal is zero when no actual prices exist', () {
      final stats = BucketStats.fromItems([
        item(id: 1, price: 15000, completed: true),
        item(id: 2, price: 40000),
      ]);

      expect(stats.actualSpentTotal, 0);
      expect(stats.actualCount, 0);
    });

    test('incomplete items with an actual price are not counted as spent', () {
      final stats = BucketStats.fromItems([
        item(id: 1, price: 1000, actual: 900),
      ]);

      expect(stats.actualSpentTotal, 0);
      expect(stats.actualCount, 0);
    });
  });

  group('SpendingStats', () {
    test('totals only completed items with an actual price', () {
      final stats = SpendingStats.fromItems([
        item(id: 1, price: 3000, completed: true, actual: 2750, category: 'Gadgets'),
        item(id: 2, price: 8000, completed: true, actual: 8000, category: 'Travel'),
        item(id: 3, price: 5000, completed: true),
        item(id: 4, price: 2000, actual: 1900),
      ]);

      expect(stats.totalSpent, 10750);
      expect(stats.purchaseCount, 2);
      expect(stats.estimatedOfCompleted, 11000);
    });

    test('byCategory groups actual spending per category', () {
      final stats = SpendingStats.fromItems([
        item(id: 1, price: 3000, completed: true, actual: 2750, category: 'Gadgets'),
        item(id: 2, price: 8000, completed: true, actual: 7900, category: 'Travel'),
        item(id: 3, price: 1000, completed: true, actual: 1000, category: 'Gadgets'),
        item(id: 4, price: 5000, completed: true),
      ]);

      expect(stats.byCategory['Gadgets'], 3750);
      expect(stats.byCategory['Travel'], 7900);
    });

    test('empty stats when no purchases', () {
      final stats = SpendingStats.fromItems([]);
      expect(stats.totalSpent, 0);
      expect(stats.purchaseCount, 0);
      expect(stats.byCategory, isEmpty);
      expect(stats.difference, 0);
    });
  });
}
