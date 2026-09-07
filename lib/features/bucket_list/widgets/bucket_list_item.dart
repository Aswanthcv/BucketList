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
    this.onEdit,
    this.onDelete,
    this.onToggleFavorite,
    this.showMenu = true,
  });

  final BucketItem item;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;
  final bool showMenu;

  String _displayPrice() {
    if (item.isCompleted && item.actualPrice != null) {
      return formatCurrency(item.actualPrice!);
    }
    return formatCurrency(item.estimatedPrice);
  }

  bool get _hasActions => onEdit != null || (showMenu && onDelete != null);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (onToggleFavorite != null) ...[
                  _FavoriteToggle(
                    key: ValueKey('favorite-${item.id}'),
                    isFavorite: item.isFavorite,
                    onToggle: onToggleFavorite!,
                  ),
                  const SizedBox(width: 12),
                ] else
                  const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                                  ? scheme.outline
                                  : scheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 6),
                      CategoryBadge(category: item.category),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                                  ? scheme.outline
                                  : AppColors.categoryColor(item.category) ??
                                      scheme.onSurface,
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
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                    if (_hasActions) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onEdit != null) ...[
                            _CardActionButton(
                              key: ValueKey('edit-${item.id}'),
                              tooltip: 'Edit',
                              icon: Icons.edit_outlined,
                              color: scheme.onSurfaceVariant,
                              onPressed: onEdit!,
                            ),
                          ],
                          if (showMenu && onDelete != null) ...[
                            _CardMenuButton(
                              color: scheme.outline,
                              onDelete: onDelete!,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 34,
        minHeight: 34,
        maxWidth: 34,
        maxHeight: 34,
      ),
      iconSize: 18,
      icon: Icon(icon, color: color),
      onPressed: onPressed,
    );
  }
}

class _CardMenuButton extends StatelessWidget {
  const _CardMenuButton({
    required this.color,
    required this.onDelete,
  });

  final Color color;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: PopupMenuButton<String>(
        tooltip: 'More options',
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(Icons.more_vert, color: color),
        onSelected: (value) {
          if (value == 'delete') {
            onDelete();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'delete',
            child: Text('Delete'),
          ),
        ],
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
