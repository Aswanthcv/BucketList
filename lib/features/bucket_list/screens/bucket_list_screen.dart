import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/categories.dart';
import '../models/bucket_item.dart';
import '../providers/bucket_list_provider.dart';
import '../providers/bucket_stats_provider.dart';
import '../widgets/bottom_summary_bar.dart';
import '../widgets/bucket_list_item.dart';
import '../widgets/complete_item_dialog.dart';
import '../widgets/empty_state.dart';
import 'add_item_screen.dart';
import 'item_details_screen.dart';

enum BucketListSort {
  newestFirst('Newest first'),
  oldestFirst('Oldest first'),
  priceLowToHigh('Price: Low → High'),
  priceHighToLow('Price: High → Low'),
  nameAZ('Name: A → Z');

  const BucketListSort(this.label);

  final String label;
}

enum BucketListStatusFilter {
  all('All'),
  active('Active'),
  completed('Completed');

  const BucketListStatusFilter(this.label);

  final String label;
}

class BucketListScreen extends ConsumerStatefulWidget {
  const BucketListScreen({super.key});

  @override
  ConsumerState<BucketListScreen> createState() => _BucketListScreenState();
}

class _BucketListScreenState extends ConsumerState<BucketListScreen> {
  String? _selectedCategory;
  BucketListSort _sort = BucketListSort.newestFirst;
  BucketListStatusFilter _status = BucketListStatusFilter.all;
  bool _favoritesOnly = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _searchActive = false;

  String get _query => _searchController.text.trim();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openAddItem(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddItemScreen()),
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
        title: const Text('Delete item?'),
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
    }
  }

  void _openSearch() {
    setState(() {
      _searchActive = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    setState(() {
      _searchActive = false;
      _searchController.clear();
    });
    _searchFocus.unfocus();
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
    });
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(bucketListProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: _searchActive ? 0 : null,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: _searchActive
              ? _buildSearchField()
              : const Text('Bucket List'),
        ),
        actions: _searchActive
            ? [
                IconButton(
                  tooltip: 'Clear search',
                  onPressed: _query.isEmpty ? null : _clearSearch,
                  icon: const Icon(Icons.close),
                ),
                const SizedBox(width: 4),
              ]
            : [
                IconButton(
                  tooltip: 'Search',
                  onPressed: _openSearch,
                  icon: const Icon(Icons.search),
                ),
                _SortButton(
                  sort: _sort,
                  onSelected: (value) {
                    setState(() {
                      _sort = value;
                    });
                  },
                ),
                const SizedBox(width: 4),
              ],
      ),
      body: Column(
        children: [
          _Header(allItems: allItems),
          _CategoryFilterBar(
            enabled: allItems.isNotEmpty,
            selected: _selectedCategory,
            onSelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),
          _StatusFilterBar(
            status: _status,
            onSelected: (status) {
              setState(() {
                _status = status;
              });
            },
          ),
          _FavoritesFilterBar(
            enabled: allItems.isNotEmpty,
            favoritesOnly: _favoritesOnly,
            onChanged: (value) {
              setState(() {
                _favoritesOnly = value;
              });
            },
          ),
          Expanded(
            child: _buildList(context, ref, allItems),
          ),
          if (allItems.isNotEmpty)
            _BottomSummary(
              allItems: allItems,
              selectedCategory: _selectedCategory,
              ref: ref,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Close search',
            onPressed: _closeSearch,
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: TextField(
              key: const ValueKey('search-field'),
              controller: _searchController,
              focusNode: _searchFocus,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search bucket items...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<BucketItem> allItems,
  ) {
    if (allItems.isEmpty) {
      return _EmptyBucketList(onAdd: () => _openAddItem(context));
    }

    final filtered = _filterItems(allItems);

    if (filtered.isEmpty) {
      return _buildEmptyResult(context);
    }

    _applySort(filtered);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return BucketListItem(
          item: item,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ItemDetailsScreen(itemId: item.id),
              ),
            );
          },
          onToggleComplete: () {
            if (item.isCompleted) {
              // Un-completing never needs an actual price.
              ref.read(bucketListProvider.notifier).toggleComplete(item.id);
            } else {
              completeItemWithActualPrice(context, ref, item);
            }
          },
          onDelete: () => _confirmDelete(context, ref, item),
          onToggleFavorite: () {
            ref.read(bucketListProvider.notifier).toggleFavorite(item.id);
          },
        );
      },
    );
  }

  List<BucketItem> _filterItems(List<BucketItem> allItems) {
    final query = _query.toLowerCase();
    return allItems.where((item) {
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      switch (_status) {
        case BucketListStatusFilter.all:
          break;
        case BucketListStatusFilter.active:
          if (item.isCompleted) return false;
          break;
        case BucketListStatusFilter.completed:
          if (!item.isCompleted) return false;
          break;
      }
      if (_favoritesOnly && !item.isFavorite) {
        return false;
      }
      if (query.isNotEmpty && !item.title.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildEmptyResult(BuildContext context) {
    if (_query.isNotEmpty) {
      return const _NoSearchResults();
    }

    switch (_status) {
      case BucketListStatusFilter.completed:
        return const _NothingCompleted();
      case BucketListStatusFilter.active:
        return const _AllCaughtUp();
      case BucketListStatusFilter.all:
        break;
    }

    if (_favoritesOnly && _selectedCategory == null) {
      return const _NoFavorites();
    }

    return _FilteredEmpty(
      category: _selectedCategory,
      onClear: () {
        setState(() {
          _selectedCategory = null;
          _favoritesOnly = false;
        });
      },
    );
  }

  void _applySort(List<BucketItem> items) {
    switch (_sort) {
      case BucketListSort.newestFirst:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case BucketListSort.oldestFirst:
        items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case BucketListSort.priceLowToHigh:
        items.sort((a, b) => a.estimatedPrice.compareTo(b.estimatedPrice));
      case BucketListSort.priceHighToLow:
        items.sort((a, b) => b.estimatedPrice.compareTo(a.estimatedPrice));
      case BucketListSort.nameAZ:
        items.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.sort,
    required this.onSelected,
  });

  final BucketListSort sort;
  final ValueChanged<BucketListSort> onSelected;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sort: ${sort.label}',
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (sheetContext) => SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sort by',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final option in BucketListSort.values)
                    ListTile(
                      leading: Icon(
                        option == sort ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: option == sort
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(option.label),
                      selected: option == sort,
                      selectedTileColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.08),
                      onTap: () {
                        onSelected(option);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
      icon: const Icon(Icons.swap_vert),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.allItems});

  final List<BucketItem> allItems;

  @override
  Widget build(BuildContext context) {
    if (allItems.isEmpty) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Text(
          '${allItems.length} ${allItems.length == 1 ? 'thing' : 'things'} to do',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.selected,
    required this.onSelected,
    required this.enabled,
  });

  final String? selected;
  final ValueChanged<String?> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final choices = ['All', ...defaultCategories];
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          for (final choice in choices)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(choice),
                selected: choice == 'All'
                    ? selected == null
                    : selected == choice,
                onSelected: enabled
                    ? (_) {
                        onSelected(choice == 'All' ? null : choice);
                      }
                    : null,
                showCheckmark: false,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.status,
    required this.onSelected,
  });

  final BucketListStatusFilter status;
  final ValueChanged<BucketListStatusFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: SegmentedButton<BucketListStatusFilter>(
        segments: [
          for (final option in BucketListStatusFilter.values)
            ButtonSegment(
              value: option,
              label: Text(option.label),
            ),
        ],
        selected: {status},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onSelected(selection.first),
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primaryContainer;
            }
            return scheme.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimaryContainer;
            }
            return scheme.onSurfaceVariant;
          }),
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w600),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoritesFilterBar extends StatelessWidget {
  const _FavoritesFilterBar({
    required this.enabled,
    required this.favoritesOnly,
    required this.onChanged,
  });

  final bool enabled;
  final bool favoritesOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SegmentedButton<bool>(
        segments: [
          const ButtonSegment(value: false, label: Text('All')),
          const ButtonSegment(
            value: true,
            label: Text('Favorites'),
            icon: Icon(Icons.star, size: 18),
          ),
        ],
        selected: {favoritesOnly},
        showSelectedIcon: false,
        onSelectionChanged:
            enabled ? (selection) => onChanged(selection.first) : null,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primaryContainer;
            }
            return scheme.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimaryContainer;
            }
            return scheme.onSurfaceVariant;
          }),
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w600),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoFavorites extends StatelessWidget {
  const _NoFavorites();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.star_border,
      title: 'No favorites yet',
      message: 'Tap the star on any item to keep it close.',
    );
  }
}

class _BottomSummary extends StatelessWidget {
  const _BottomSummary({
    required this.allItems,
    required this.selectedCategory,
    required this.ref,
  });

  final List<BucketItem> allItems;
  final String? selectedCategory;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (allItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final stats = ref.watch(bucketStatsProvider);
    return BottomSummaryBar(stats: stats);
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.search_off,
      title: 'Nothing found',
      message: 'Try a different search.',
    );
  }
}

class _NothingCompleted extends StatelessWidget {
  const _NothingCompleted();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.inbox_outlined,
      title: 'Nothing completed yet',
      message: 'Time to make something happen 🚀',
    );
  }
}

class _AllCaughtUp extends StatelessWidget {
  const _AllCaughtUp();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.task_alt,
      title: 'All caught up ✓',
      message: "You've completed everything.",
    );
  }
}

class _EmptyBucketList extends StatelessWidget {
  const _EmptyBucketList({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.explore_outlined,
      title: 'Your bucket list is empty',
      message: 'Start adding the things you want to do, buy, or achieve.',
      actionLabel: 'Add Item',
      onAction: onAdd,
    );
  }
}

class _FilteredEmpty extends StatelessWidget {
  const _FilteredEmpty({
    required this.category,
    required this.onClear,
  });

  final String? category;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: 'Nothing here yet',
            message: 'No items match this category.',
          ),
          if (category != null)
            TextButton(
              onPressed: onClear,
              child: const Text('Show all items'),
            ),
        ],
      ),
    );
  }
}
