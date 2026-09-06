import 'package:flutter/material.dart';
import 'currency_formatter.dart';

/// Confirms price values that need extra care before they are saved.
///
/// Returns `true` when the value needs no confirmation or the user confirmed.
/// A value above 1 lakh asks for confirmation; a zero value asks to confirm
/// that nothing needs to be spent.
Future<bool> confirmPriceValue(
  BuildContext context, {
  required double value,
  required String label,
}) async {
  if (value > 100000) {
    return _showConfirmation(
      context,
      title: 'Are you sure?',
      message: 'The $label is ${formatCurrency(value)} '
          'which is more than ₹1,00,000. Continue?',
    );
  }
  if (value == 0) {
    return _showConfirmation(
      context,
      title: 'Nothing to spend?',
      message: 'The $label is ₹0. Do you really not need to spend anything?',
    );
  }
  return true;
}

Future<bool> _showConfirmation(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Yes'),
        ),
      ],
    ),
  );
  return result ?? false;
}