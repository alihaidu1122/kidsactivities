import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/dashboard_text_styles.dart';
import '../../../app/theme/dashboard_tokens.dart';

class DashboardTopBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardTopBar({
    super.key,
    this.onMenuTap,
    this.showMenuButton = false,
    required this.onAddListing,
    this.onMessagesTap,
    this.onNotificationsTap,
    this.userInitials = 'JG',
    this.searchController,
    this.onSearchChanged,
    this.onSettings,
    this.onSignOut,
    this.themeToggle,
  });

  final VoidCallback? onMenuTap;
  final bool showMenuButton;
  final VoidCallback onAddListing;
  final VoidCallback? onMessagesTap;
  final VoidCallback? onNotificationsTap;
  final String userInitials;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSettings;
  final VoidCallback? onSignOut;
  /// Optional theme control (Light / Dark / System) for dashboards.
  final Widget? themeToggle;

  @override
  Size get preferredSize => const Size.fromHeight(54);

  @override
  Widget build(BuildContext context) {
    final d = context.dash;
    return Material(
      color: d.bgSecondary,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: d.borderColor),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            if (showMenuButton) ...[
              IconButton(
                icon: Icon(Icons.menu, color: d.textMuted, size: 22),
                onPressed: onMenuTap,
              ),
              const SizedBox(width: 8),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: DashboardTextStyles.body(d),
                spellCheckConfiguration: SpellCheckConfiguration.disabled(),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: d.bgPrimary,
                  hintText: 'Search or type command…',
                  hintStyle: DashboardTextStyles.label(d).copyWith(color: d.textFaint),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 8, right: 4),
                    child: Center(
                      widthFactor: 1,
                      child: Text('🔍', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  contentPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: d.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: d.accentBlue),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: d.borderColor),
                  ),
                ),
              ),
            ),
            const Spacer(),
            if (themeToggle != null) themeToggle!,
            if (themeToggle != null) const SizedBox(width: 4),
            TextButton(
              onPressed: onAddListing,
              style: TextButton.styleFrom(
                backgroundColor: d.accentBlue,
                foregroundColor: Theme.of(context).brightness == Brightness.dark ? d.textPrimary : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                '+ Add Listing',
                style: DashboardTextStyles.button(d).copyWith(
                  color: Theme.of(context).brightness == Brightness.dark ? d.textPrimary : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _IconDotButton(
              d: d,
              emoji: '💬',
              showDot: false,
              onTap: onMessagesTap,
            ),
            const SizedBox(width: 10),
            _IconDotButton(
              d: d,
              emoji: '🔔',
              showDot: true,
              onTap: onNotificationsTap,
            ),
            const SizedBox(width: 10),
            PopupMenuButton<String>(
              offset: const Offset(0, 40),
              color: d.bgSecondary,
              child: _AvatarCircle(d: d, initials: userInitials),
              onSelected: (v) {
                if (v == 'settings') onSettings?.call();
                if (v == 'logout') onSignOut?.call();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'settings',
                  child: Text('Settings', style: DashboardTextStyles.body(d)),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Text('Sign out', style: DashboardTextStyles.body(d)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconDotButton extends StatelessWidget {
  const _IconDotButton({
    required this.d,
    required this.emoji,
    required this.showDot,
    this.onTap,
  });

  final DashboardTokens d;
  final String emoji;
  final bool showDot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: d.bgTertiary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(child: Text(emoji, style: const TextStyle(fontSize: 14))),
              if (showDot)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: d.notifyDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.d, required this.initials});

  final DashboardTokens d;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
        ),
      ),
      child: Text(
        initials.length > 2 ? initials.substring(0, 2).toUpperCase() : initials.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
