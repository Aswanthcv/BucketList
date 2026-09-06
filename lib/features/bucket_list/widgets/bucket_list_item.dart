import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../models/bucket_item.dart';
import '../utils/currency_formatter.dart';

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    super.key,
    required this.category,
    this.large = false,
  });

  final String category;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(category) ?? AppColors.other;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 5 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: large ? 0.12 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: large ? 13 : 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class BucketListItem extends StatelessWidget {
  const BucketListItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.onToggleComplete,
    this.onDelete,
    this.onToggleFavorite,
    this.showMenu = true,
  });

  final BucketItem item;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;
  final bool showMenu;

  String _displayPrice() {
    if (item.isCompleted && item.actualPrice != null) {
      return formatCurrency(item.actualPrice!);
    }
    return formatCurrency(item.estimatedPrice);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isCompleted
              ? Theme.of(context).colorScheme.outlineVariant
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _CompletionCheckbox(
                  key: ValueKey('toggle-${item.id}'),
                  isCompleted: item.isCompleted,
                  color: AppColors.categoryColor(item.category),
                  onChanged: onToggleComplete,
                ),
                if (onToggleFavorite != null) ...[
                  const SizedBox(width: 10),
                  _FavoriteToggle(
                    key: ValueKey('favorite-${item.id}'),
                    isFavorite: item.isFavorite,
                    onToggle: onToggleFavorite!,
                  ),
                  const SizedBox(width: 8),
                ] else
                  const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: item.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationThickness: 2,
                              color: item.isCompleted
                                  ? Theme.of(context).colorScheme.outline
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: CategoryBadge(category: item.category),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 96,
                          child: Text(
                            _displayPrice(),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: item.isCompleted
                                      ? Theme.of(context).colorScheme.outline
                                      : AppColors.categoryColor(item.category) ??
                                          Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ),
                        if (item.isCompleted && item.actualPrice != null) ...[
                          const SizedBox(height: 1),
                          SizedBox(
                            width: 96,
                            child: Text(
                              'actual',
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                        if (showMenu && onDelete != null) ...[
                          const SizedBox(height: 2),
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              iconSize: 18,
                              icon: Icon(
                                Icons.more_vert,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              onSelected: (value) {
                                if (value == 'delete') {
                                  onDelete!();
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionCheckbox extends StatelessWidget {
  const _CompletionCheckbox({
    super.key,
    required this.isCompleted,
    required this.color,
    required this.onChanged,
  });

  final bool isCompleted;
  final Color? color;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged,
      child: AnimatedScale(
        scale: isCompleted ? 1.0 : 0.9,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? (color ?? Theme.of(context).colorScheme.primary)
                : Colors.transparent,
            border: Border.all(
              width: 2,
              color: isCompleted
                  ? (color ?? Theme.of(context).colorScheme.primary)
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          child: isCompleted
              ? const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}

class _FavoriteToggle extends StatelessWidget {
  const _FavoriteToggle({
    super.key,
    required this.isFavorite,
    required this.onToggle,
  });

  final bool isFavorite;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final color = isFavorite
        ? const Color(0xFFFFB300)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 28,
        minHeight: 28,
        maxWidth: 28,
        maxHeight: 28,
      ),
      iconSize: 20,
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      onPressed: onToggle,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          isFavorite ? Icons.star : Icons.star_border,
          key: ValueKey('favorite-icon-$isFavorite'),
          size: 20,
          color: color,
        ),
      ),
    );
  }
}
