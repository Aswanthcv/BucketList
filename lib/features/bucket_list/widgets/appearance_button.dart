import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/theme_provider.dart';

class AppearanceButton extends ConsumerWidget {
  const AppearanceButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Appearance',
      icon: Icon(
        Icons.palette_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 26,
      ),
      splashRadius: 24,
      onSelected: (mode) {
        ref.read(themeModeProvider.notifier).setTheme(mode);
      },
      itemBuilder: (context) => [
        _menuItem(
          context,
          value: ThemeMode.light,
          current: themeMode,
          icon: Icons.light_mode_outlined,
          label: 'Light',
        ),
        _menuItem(
          context,
          value: ThemeMode.dark,
          current: themeMode,
          icon: Icons.dark_mode_outlined,
          label: 'Dark',
        ),
      ],
    );
  }

  PopupMenuItem<ThemeMode> _menuItem(
    BuildContext context, {
    required ThemeMode value,
    required ThemeMode current,
    required IconData icon,
    required String label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = value == current;
    return PopupMenuItem<ThemeMode>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          if (selected) Icon(Icons.check, size: 18, color: scheme.primary),
        ],
      ),
    );
  }
}