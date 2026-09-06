import 'package:flutter/material.dart';

/// Overlay card shown on the first launch to walk the user through the app.
class TutorialCard extends StatelessWidget {
  const TutorialCard({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  static const _tips = <(IconData, String)>[
    (Icons.add, 'Tap + to add a goal and set a category.'),
    (Icons.touch_app_outlined, 'Tap a goal to mark it done and enter the actual price.'),
    (Icons.star_outline, 'Star to favorite; use the pencil to edit.'),
    (Icons.currency_rupee, 'Large amounts (> ₹1,00,000) and zero ask to confirm.'),
    (Icons.receipt_long_outlined, 'See what you spent on the Spending tab.'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colors.surfaceContainerHigh,
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.55,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Welcome to BucketList',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _tips.length; i++) ...[
                _TipRow(icon: _tips[i].$1, label: _tips[i].$2),
                if (i < _tips.length - 1) const SizedBox(height: 8),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onDismiss,
                icon: const Icon(Icons.check),
                label: const Text('Got it'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: colors.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                ),
          ),
        ),
      ],
    );
  }
}