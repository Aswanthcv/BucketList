import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bucket_item.dart';
import '../providers/bucket_list_provider.dart';
import '../providers/bucket_stats_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/appearance_button.dart';
import '../widgets/bucket_list_item.dart';
import '../widgets/complete_item_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import 'add_item_screen.dart';
import 'bucket_list_screen.dart';
import 'edit_item_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(bucketStatsProvider);
    final items = ref.watch(bucketListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DashboardHeader(stats: stats),
            Expanded(
              child: _buildBody(context, ref, items, stats),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<BucketItem> items,
    BucketStats stats,
  ) {
    if (items.isEmpty) {
      return _DashboardEmpty(onAdd: () => _openAddItem(context));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        _RecentItemsSection(
          items: items,
          onViewAll: () => _openBucketList(context),
          onTap: (item) => _toggleComplete(context, ref, item),
          onEdit: (item) => _openEditItem(context, item),
          onToggleFavorite: (item) {
            ref
                .read(bucketListProvider.notifier)
                .toggleFavorite(item.id);
          },
        ),
        if (items.any((i) => i.isFavorite && !i.isCompleted)) ...[
          const SizedBox(height: 24),
          _PrioritiesSection(
            items: items,
            onTap: (item) => _toggleComplete(context, ref, item),
            onEdit: (item) => _openEditItem(context, item),
            onToggleFavorite: (item) {
              ref
                  .read(bucketListProvider.notifier)
                  .toggleFavorite(item.id);
            },
          ),
        ],
        const SizedBox(height: 24),
        _ProgressSummary(stats: stats),
        const SizedBox(height: 24),
        _CostSummary(
          stats: stats,
          onViewAll: () => _openBucketList(context),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _openAddItem(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddItemScreen()),
    );
  }

  void _openBucketList(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const BucketListScreen()),
    );
  }

  void _openEditItem(BuildContext context, BucketItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditItemScreen(item: item),
      ),
    );
  }

  void _toggleComplete(BuildContext context, WidgetRef ref, BucketItem item) {
    if (item.isCompleted) {
      // Un-completing never needs an actual price.
      ref.read(bucketListProvider.notifier).toggleComplete(item.id);
    } else {
      completeItemWithActualPrice(context, ref, item);
    }
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.stats});

  final BucketStats stats;

  String get _line1 {
    if (stats.totalItems == 0) {
      return 'Your list is empty.';
    }
    if (stats.remainingItems == 0) {
      return 'All ${stats.completedItems} done ✓';
    }
    final remaining = stats.remainingItems;
    return '$remaining ${remaining == 1 ? 'thing' : 'things'} to make happen.';
  }

  String? get _line2 {
    if (stats.totalItems == 0 || stats.remainingItems == 0) {
      return null;
    }
    if (stats.completedItems == 0) {
      return null;
    }
    return '${stats.completedItems} already done ✓';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BucketList',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _line1,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                if (_line2 != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _line2!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const AppearanceButton(),
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.stats});

  final BucketStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (stats.progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$percent%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: stats.progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${stats.completedItems} of ${stats.totalItems} done',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${stats.remainingItems} remaining',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentItemsSection extends StatelessWidget {
  const _RecentItemsSection({
    required this.items,
    required this.onViewAll,
    required this.onTap,
    required this.onEdit,
    required this.onToggleFavorite,
  });

  final List<BucketItem> items;
  final VoidCallback onViewAll;
  final ValueChanged<BucketItem> onTap;
  final ValueChanged<BucketItem> onEdit;
  final ValueChanged<BucketItem> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final recent = [...items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final shown = recent.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Recent items',
          trailing: TextButton(
            onPressed: onViewAll,
            child: const Text('View all'),
          ),
        ),
        const SizedBox(height: 12),
        for (final item in shown) ...[
          BucketListItem(
            item: item,
            onTap: () => onTap(item),
            onEdit: () => onEdit(item),
            onToggleFavorite: () => onToggleFavorite(item),
            showMenu: false,
          ),
          if (item != shown.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _PrioritiesSection extends StatelessWidget {
  const _PrioritiesSection({
    required this.items,
    required this.onTap,
    required this.onEdit,
    required this.onToggleFavorite,
  });

  final List<BucketItem> items;
  final ValueChanged<BucketItem> onTap;
  final ValueChanged<BucketItem> onEdit;
  final ValueChanged<BucketItem> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final priorities = items
        .where((i) => i.isFavorite && !i.isCompleted)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final shown = priorities.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: '⭐ Priorities'),
        const SizedBox(height: 12),
        for (final item in shown) ...[
          BucketListItem(
            item: item,
            onTap: () => onTap(item),
            onEdit: () => onEdit(item),
            onToggleFavorite: () => onToggleFavorite(item),
            showMenu: false,
          ),
          if (item != shown.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _CostSummary extends StatelessWidget {
  const _CostSummary({
    required this.stats,
    required this.onViewAll,
  });

  final BucketStats stats;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Estimated cost',
            trailing: TextButton(
              onPressed: onViewAll,
              child: const Text('Details'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatCurrency(stats.totalCost),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '${stats.remainingItems} remaining • ${stats.completedItems} completed',
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _CostRow(
            label: 'Remaining',
            value: stats.remainingCost,
            bold: true,
          ),
          const SizedBox(height: 8),
          _CostRow(
            label: 'Actually spent',
            value: stats.actualSpentTotal,
            color: theme.colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
  });

  final String label;
  final double value;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          formatCurrency(value),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _DashboardEmpty extends StatelessWidget {
  const _DashboardEmpty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: EmptyState(
        icon: Icons.explore_outlined,
        title: 'Your bucket list is empty',
        message: 'Start adding the things you want to do, buy, or achieve.',
        actionLabel: 'Add Item',
        onAction: onAdd,
      ),
    );
  }
}