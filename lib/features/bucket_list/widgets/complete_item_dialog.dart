import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bucket_item.dart';
import '../providers/bucket_list_provider.dart';
import '../utils/currency_formatter.dart';

/// Completes an item, prompting for the actual price when none is recorded.
///
/// If the item already has an actual price, it is completed immediately.
/// Otherwise a dialog asks for the actual price (optional) before completing.
Future<void> completeItemWithActualPrice(
  BuildContext context,
  WidgetRef ref,
  BucketItem item,
) async {
  if (item.actualPrice != null) {
    ref
        .read(bucketListProvider.notifier)
        .completeItem(item.id, actualPrice: item.actualPrice);
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (_) => CompleteItemDialog(item: item, ref: ref),
  );
}

/// Shown when completing an item that has no recorded actual price.
class CompleteItemDialog extends StatefulWidget {
  const CompleteItemDialog({
    super.key,
    required this.item,
    required this.ref,
  });

  final BucketItem item;
  final WidgetRef ref;

  @override
  State<CompleteItemDialog> createState() => _CompleteItemDialogState();
}

class _CompleteItemDialogState extends State<CompleteItemDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _complete() {
    final raw = _controller.text.trim();
    double? actual;
    if (raw.isNotEmpty) {
      final parsed = double.tryParse(raw);
      if (parsed != null && parsed >= 0) {
        actual = parsed;
      }
    }
    widget.ref
        .read(bucketListProvider.notifier)
        .completeItem(widget.item.id, actualPrice: actual);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return AlertDialog(
      title: Text('Complete "${item.title}"?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Estimated price',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              Text(
                formatCurrency(item.estimatedPrice),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: false,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Actual price',
              hintText: 'What you actually spent',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Leave the actual price empty if not recorded.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _complete,
          child: const Text('Complete'),
        ),
      ],
    );
  }
}
