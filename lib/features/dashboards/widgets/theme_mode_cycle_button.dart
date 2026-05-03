import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/dashboard_tokens.dart';
import '../../../app/theme/theme_controller.dart';

/// Theme toggle with visible background so it reads on light and dark shells.
class ThemeModeCycleButton extends ConsumerWidget {
  const ThemeModeCycleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final ctrl = ref.read(themeModeProvider.notifier);
    final d = context.dash;

    final icon = switch (mode) {
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.system => Icons.brightness_auto_rounded,
    };

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: 'Theme: ${mode.name}',
        child: Material(
          color: d.bgTertiary,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              final next = switch (mode) {
                ThemeMode.system => ThemeMode.light,
                ThemeMode.light => ThemeMode.dark,
                ThemeMode.dark => ThemeMode.system,
              };
              await ctrl.setThemeMode(next);
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: d.accentBlue, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
