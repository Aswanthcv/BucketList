import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bucket_item.dart';
import 'bucket_list_provider.dart';

class BucketStats {
  final int totalItems;
  final int completedItems;
  final int remainingItems;
  final double totalCost;
  final double remainingCost;
  final double completedCost;
  final double actualSpentTotal;
  final int actualCount;

  const BucketStats({
    required this.totalItems,
    required this.completedItems,
    required this.remainingItems,
    required this.totalCost,
    required this.remainingCost,
    required this.completedCost,
    required this.actualSpentTotal,
    required this.actualCount,
  });

  double get progress {
    if (totalItems == 0) {
      return 0;
    }
    return completedItems / totalItems;
  }

  static BucketStats fromItems(List<BucketItem> items) {
    final totalItems = items.length;
    final completedItems = items.where((i) => i.isCompleted).length;
    final remainingItems = totalItems - completedItems;

    var totalCost = 0.0;
    var completedCost = 0.0;
    var remainingCost = 0.0;
    var actualSpentTotal = 0.0;
    var actualCount = 0;

    for (final item in items) {
      totalCost += item.estimatedPrice;
      if (item.isCompleted) {
        completedCost += item.estimatedPrice;
      } else {
        remainingCost += item.estimatedPrice;
      }
      final actual = item.actualPrice;
      if (item.isCompleted && actual != null) {
        actualSpentTotal += actual;
        actualCount += 1;
      }
    }

    return BucketStats(
      totalItems: totalItems,
      completedItems: completedItems,
      remainingItems: remainingItems,
      totalCost: totalCost,
      completedCost: completedCost,
      remainingCost: remainingCost,
      actualSpentTotal: actualSpentTotal,
      actualCount: actualCount,
    );
  }
}

class SpendingStats {
  final double totalSpent;
  final int purchaseCount;
  final Map<String, double> byCategory;
  final double estimatedOfCompleted;
  final double actualOfCompleted;

  const SpendingStats({
    required this.totalSpent,
    required this.purchaseCount,
    required this.byCategory,
    required this.estimatedOfCompleted,
    required this.actualOfCompleted,
  });

  double get difference => actualOfCompleted - estimatedOfCompleted;

  static SpendingStats fromItems(List<BucketItem> items) {
    final purchased = items
        .where((i) => i.isCompleted && i.actualPrice != null)
        .toList();

    var totalSpent = 0.0;
    var estimatedOfCompleted = 0.0;
    final byCategory = <String, double>{};

    for (final item in purchased) {
      final actual = item.actualPrice!;
      totalSpent += actual;
      estimatedOfCompleted += item.estimatedPrice;
      byCategory[item.category] = (byCategory[item.category] ?? 0) + actual;
    }

    return SpendingStats(
      totalSpent: totalSpent,
      purchaseCount: purchased.length,
      byCategory: byCategory,
      estimatedOfCompleted: estimatedOfCompleted,
      actualOfCompleted: totalSpent,
    );
  }
}

final bucketStatsProvider = Provider<BucketStats>((ref) {
  final items = ref.watch(bucketListProvider);
  return BucketStats.fromItems(items);
});

final spendingStatsProvider = Provider<SpendingStats>((ref) {
  final items = ref.watch(bucketListProvider);
  return SpendingStats.fromItems(items);
});
