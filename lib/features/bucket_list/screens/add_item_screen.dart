import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bucket_item.dart';
import '../providers/bucket_list_provider.dart';
import '../widgets/item_form.dart';

class AddItemScreen extends ConsumerWidget {
  const AddItemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Bucket List'),
      ),
      body: SafeArea(
        child: ItemForm(
          submitLabel: 'Add Goal',
          onSubmit: (title, category, price, actualPrice, note) {
            final item = BucketItem(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              title: title,
              category: category,
              estimatedPrice: price,
              note: note,
              createdAt: DateTime.now(),
              isCompleted: false,
              actualPrice: actualPrice,
            );

            try {
              ref.read(bucketListProvider.notifier).addItem(item);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Goal added successfully')),
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
