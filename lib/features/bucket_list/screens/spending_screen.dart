import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../models/bucket_item.dart';
import '../providers/bucket_list_provider.dart';
import '../providers/bucket_stats_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/bucket_list_item.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import 'item_details_screen.dart';

class SpendingScreen extends ConsumerWidget {
  const SpendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(bucketListProvider);
    final spending = ref.watch(spendingStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending'),
      ),
      body: SafeArea(
        child: items.where((i) => i.isCompleted && i.actualPrice != null).isEmpty
            ? const _SpendingEmpty()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _SpentSummary(spending: spending),
                  const SizedBox(height: 24),
                  _RecentSpending(items: items),
                  const SizedBox(height: 24),
                  _CategoryBreakdown(spending: spending),
                ],
              ),
      ),
    );
  }
}

class _SpentSummary extends StatelessWidget {
  const _SpentSummary({required this.spending});

  final SpendingStats spending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF00A896)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actually spent',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: spending.totalSpent),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, value, _) => Text(
              formatCurrency(value),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${spending.purchaseCount} ${spending.purchaseCount == 1 ? 'purchase' : 'purchases'}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSpending extends StatelessWidget {
  const _RecentSpending({required this.items});

  final List<BucketItem> items;

  @override
  Widget build(BuildContext context) {
    final purchased = items
        .where((i) => i.isCompleted && i.actualPrice != null)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Recent spending'),
        const SizedBox(height: 12),
        for (final item in purchased) ...[
          BucketListItem(
            item: item,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ItemDetailsScreen(itemId: item.id),
                ),
              );
            },
            onToggleComplete: () {},
            showMenu: false,
          ),
          if (item != purchased.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.spending});

  final SpendingStats spending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = spending.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'By category'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: entries.isEmpty
              ? Text(
                  'No categories yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < entries.length; i++) ...[
                      _CategoryRow(
                        category: entries[i].key,
                        amount: entries[i].value,
                      ),
                      if (i != entries.length - 1) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.amount});

  final String category;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColors.categoryColor(category) ?? AppColors.other;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            category,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatCurrency(amount),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SpendingEmpty extends StatelessWidget {
  const _SpendingEmpty();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'No spending yet',
      message: 'Complete something from your bucket list\n'
          'and record what you actually spent.',
    );
  }
}
