import 'package:flutter/material.dart';
import '../../../constants/categories.dart';
import '../../../theme/app_theme.dart';
import '../utils/price_confirmation.dart';

class ItemForm extends StatefulWidget {
  const ItemForm({
    super.key,
    this.initialTitle,
    this.initialCategory,
    this.initialPrice,
    this.initialActualPrice,
    this.initialNote,
    required this.submitLabel,
    required this.onSubmit,
  });

  final String? initialTitle;
  final String? initialCategory;
  final double? initialPrice;
  final double? initialActualPrice;
  final String? initialNote;
  final String submitLabel;
  final void Function(
          String title, String category, double price, double? actualPrice, String? note)
      onSubmit;

  @override
  State<ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<ItemForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _actualPriceController;
  late final TextEditingController _noteController;

  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _priceController = TextEditingController(
      text: widget.initialPrice == null ? '' : _formatPrice(widget.initialPrice!),
    );
    _actualPriceController = TextEditingController(
      text: widget.initialActualPrice == null
          ? ''
          : _formatPrice(widget.initialActualPrice!),
    );
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _selectedCategory = widget.initialCategory;
  }

  String _formatPrice(double price) {
    if (price == price.roundToDouble()) {
      return price.toInt().toString();
    }
    return price.toString();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _actualPriceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String? _validateOptionalPrice(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final price = double.tryParse(raw.trim());
    if (price == null) {
      return 'Please enter a valid price';
    }
    if (price < 0) {
      return 'Price cannot be negative';
    }
    return null;
  }

  double? _parseOptionalPrice(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return double.tryParse(trimmed);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final actualPrice = _parseOptionalPrice(_actualPriceController.text);
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    if (price > 100000 || price == 0) {
      final confirmed = await confirmPriceValue(
        context,
        value: price,
        label: 'estimated price',
      );
      if (!confirmed || !mounted) return;
    }

    if (actualPrice != null && (actualPrice > 100000 || actualPrice == 0)) {
      final confirmed = await confirmPriceValue(
        context,
        value: actualPrice,
        label: 'actual price',
      );
      if (!confirmed || !mounted) return;
    }

    widget.onSubmit(
      _titleController.text.trim(),
      _selectedCategory!,
      price,
      actualPrice,
      note,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'What do you want to add?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _titleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Goal name',
              hintText: 'e.g. Banana',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a goal name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: [
              for (final category in defaultCategories)
                DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.categoryColor(category) ?? AppColors.other,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(category),
                    ],
                  ),
                ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a category';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Estimated price',
              hintText: 'Enter Amount',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an estimated price';
              }
              final price = double.tryParse(value.trim());
              if (price == null) {
                return 'Please enter a valid price';
              }
              if (price < 0) {
                return 'Price cannot be negative';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _actualPriceController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Actual price (optional)',
              hintText: 'Enter Amount',
              helperText: 'What you actually spent',
            ),
            validator: _validateOptionalPrice,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _noteController,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check),
            label: Text(widget.submitLabel),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
