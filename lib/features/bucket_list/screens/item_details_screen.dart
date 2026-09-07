import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/bucket_item.dart';
import '../providers/bucket_list_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/spending_math.dart';
import '../widgets/bucket_list_item.dart';
import '../widgets/complete_item_dialog.dart';
import 'edit_item_screen.dart';

class ItemDetailsScreen extends ConsumerWidget {
  const ItemDetailsScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(bucketListProvider);
    BucketItem? item;
    for (final i in items) {
      if (i.id == itemId) {
        item = i;
        break;
      }
    }

    // Item was deleted.
    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Goal Details')),
        body: const Center(child: Text('This goal no longer exists.')),
      );
    }
    final currentItem = item;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Details'),
        actions: [
          IconButton(
            key: ValueKey('favorite-${currentItem.id}'),
            tooltip: currentItem.isFavorite
                ? 'Remove from favorites'
                : 'Add to favorites',
            onPressed: () {
              ref
                  .read(bucketListProvider.notifier)
                  .toggleFavorite(currentItem.id);
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                currentItem.isFavorite ? Icons.star : Icons.star_border,
                key: ValueKey('favorite-icon-${currentItem.isFavorite}'),
                color: currentItem.isFavorite
                    ? const Color(0xFFFFB300)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _SummaryHeader(item: currentItem),
            const SizedBox(height: 24),
            _PriceCard(item: currentItem),
            const SizedBox(height: 16),
            _InfoCard(item: currentItem),
            const SizedBox(height: 24),
            _Actions(
              item: currentItem,
              ref: ref,
              onEdit: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditItemScreen(item: currentItem),
                  ),
                );
              },
              onDelete: () => _confirmDelete(context, ref, currentItem),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BucketItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(bucketListProvider.notifier).deleteItem(item.id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.item});

  final BucketItem item;

  @override
  Widget build(BuildContext context) {
    final isCompleted = item.isCompleted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      decorationThickness: 2,
                      color: isCompleted
                          ? Theme.of(context).colorScheme.outline
                          : Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (item.category.isNotEmpty) ...[
              CategoryBadge(category: item.category, large: true),
              const SizedBox(width: 10),
            ],
            Text(
              isCompleted ? '✓ Completed' : 'Not completed',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isCompleted
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.item});

  final BucketItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actual = item.actualPrice;
    final comparison = compareEstimate(item.estimatedPrice, actual);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PricePill(
                  label: 'Estimated',
                  value: formatCurrency(item.estimatedPrice),
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PricePill(
                  label: 'Actual',
                  value: actual == null ? 'Not recorded' : formatCurrency(actual),
                  color: actual == null
                      ? theme.colorScheme.outline
                      : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          if (comparison != null && item.isCompleted) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    comparison.relation == EstimateRelation.over
                        ? Icons.trending_up
                        : Icons.savings_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      differenceLabel(context, item.estimatedPrice, actual),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.item});

  final BucketItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (item.note != null && item.note!.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.notes_outlined,
              label: 'Note',
              value: item.note!,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
          ],
          _InfoRow(
            icon: Icons.category_outlined,
            label: 'Category',
            value: item.category,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.task_alt_outlined,
            label: 'Status',
            value: item.isCompleted ? 'Completed' : 'Not completed',
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _InfoRow(
            icon: item.isFavorite ? Icons.star : Icons.star_border,
            label: 'Favorite',
            value: item.isFavorite ? '★ Favorite' : 'Not favorite',
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Added on',
            value: DateFormat('MMMM d, y').format(item.createdAt),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.item,
    required this.ref,
    required this.onEdit,
    required this.onDelete,
  });

  final BucketItem item;
  final WidgetRef ref;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!item.isCompleted)
          FilledButton.icon(
            onPressed: () => _showCompleteDialog(context),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark as Completed'),
          )
        else
          OutlinedButton.icon(
            onPressed: () {
              ref.read(bucketListProvider.notifier).toggleComplete(item.id);
            },
            icon: const Icon(Icons.undo),
            label: const Text('Mark Incomplete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }

  void _showCompleteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => CompleteItemDialog(
        item: item,
        ref: ref,
      ),
    );
  }
}
