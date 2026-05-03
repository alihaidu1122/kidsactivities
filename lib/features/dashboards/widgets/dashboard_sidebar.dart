import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/dashboard_text_styles.dart';
import '../../../app/theme/dashboard_tokens.dart';
import '../../../app/theme/theme_controller.dart';

class DashboardNavItemData {
  const DashboardNavItemData({
    required this.emoji,
    required this.label,
    this.badge,
    this.trailingArrow = false,
  });

  final String emoji;
  final String label;
  final int? badge;
  final bool trailingArrow;
}

class DashboardSidebar extends ConsumerWidget {
  const DashboardSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<DashboardNavItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = context.dash;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 200,
      color: d.bgSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LogoArea(d: d),
          Container(height: 1, color: d.borderColor),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final it = items[i];
                final active = i == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _NavRow(
                    d: d,
                    emoji: it.emoji,
                    label: it.label,
                    badge: it.badge,
                    showArrow: it.trailingArrow,
                    active: active,
                    onTap: () => onSelect(i),
                  ),
                );
              },
            ),
          ),
          Container(height: 1, color: d.borderColor),
          _ThemeSegment(
            d: d,
            isDark: isDark,
            onLight: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
            onDark: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _LogoArea extends StatelessWidget {
  const _LogoArea({required this.d});

  final DashboardTokens d;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: d.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
              ),
            ),
            child: const Text('🎯', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: 'Kids', style: DashboardTextStyles.logo(d)),
                TextSpan(
                  text: 'Hub',
                  style: DashboardTextStyles.logo(d).copyWith(color: d.accentBlue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatefulWidget {
  const _NavRow({
    required this.d,
    required this.emoji,
    required this.label,
    required this.badge,
    required this.showArrow,
    required this.active,
    required this.onTap,
  });

  final DashboardTokens d;
  final String emoji;
  final String label;
  final int? badge;
  final bool showArrow;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_NavRow> createState() => _NavRowState();
}

class _NavRowState extends State<_NavRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    Color bg;
    Color fg;
    if (widget.active) {
      bg = d.accentBlue;
      fg = Theme.of(context).brightness == Brightness.dark ? d.textPrimary : Colors.white;
    } else if (_hover) {
      bg = d.bgTertiary;
      fg = d.textSecondary;
    } else {
      bg = Colors.transparent;
      fg = d.textMuted;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
            child: Row(
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: DashboardTextStyles.navItem(d).copyWith(color: fg),
                  ),
                ),
                if (widget.badge != null && widget.badge! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.badge! > 99 ? '99+' : widget.badge}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (widget.showArrow)
                  Text('›', style: TextStyle(color: fg, fontSize: 18, height: 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  const _ThemeSegment({
    required this.d,
    required this.isDark,
    required this.onLight,
    required this.onDark,
  });

  final DashboardTokens d;
  final bool isDark;
  final VoidCallback onLight;
  final VoidCallback onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: d.bgSecondary,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: d.bgPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SegBtn(
                d: d,
                label: '☀ Light',
                active: !isDark,
                onTap: onLight,
              ),
            ),
            Expanded(
              child: _SegBtn(
                d: d,
                label: '◑ Dark',
                active: isDark,
                onTap: onDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  const _SegBtn({required this.d, required this.label, required this.active, required this.onTap});

  final DashboardTokens d;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? d.bgTertiary : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: active ? d.textSecondary : d.textMuted,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
