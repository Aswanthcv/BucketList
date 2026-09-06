import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bucket_item.dart';
import '../providers/bucket_list_provider.dart';
import '../widgets/item_form.dart';

class EditItemScreen extends ConsumerWidget {
  const EditItemScreen({super.key, required this.item});

  final BucketItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Item'),
      ),
      body: SafeArea(
        child: ItemForm(
          initialTitle: item.title,
          initialCategory: item.category,
          initialPrice: item.estimatedPrice,
          initialActualPrice: item.actualPrice,
          initialNote: item.note,
          submitLabel: 'Save Changes',
          onSubmit: (title, category, price, actualPrice, note) {
            final updated = BucketItem(
              id: item.id,
              title: title,
              category: category,
              estimatedPrice: price,
              note: note,
              createdAt: item.createdAt,
              isCompleted: item.isCompleted,
              actualPrice: actualPrice,
              isFavorite: item.isFavorite,
            );

            try {
              ref.read(bucketListProvider.notifier).updateItem(updated);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Changes saved')),
                );
                Navigator.of(context).pop();
              }
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Something went wrong. Please try again.'),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }
}
