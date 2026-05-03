import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/dashboard_tokens.dart';
import '../../auth/auth_providers.dart';
import 'dashboard_sidebar.dart';
import 'dashboard_topbar.dart';
import 'theme_mode_cycle_button.dart';

/// Desktop-first layout: 200px sidebar, 54px top bar, scrollable content.
class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({
    super.key,
    required this.navItems,
    required this.selectedIndex,
    required this.onNavSelected,
    required this.child,
    required this.onAddListing,
    this.onSettings,
    this.onSignOut,
  });

  final List<DashboardNavItemData> navItems;
  final int selectedIndex;
  final ValueChanged<int> onNavSelected;
  final Widget child;
  final VoidCallback onAddListing;
  final VoidCallback? onSettings;
  final VoidCallback? onSignOut;

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openMobileNav() {
    final d = context.dash;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: d.bgSecondary,
      builder: (context) => SafeArea(
        child: ListView(
          children: [
            for (var i = 0; i < widget.navItems.length; i++)
              ListTile(
                leading: Text(widget.navItems[i].emoji),
                title: Text(
                  widget.navItems[i].label,
                  style: TextStyle(
                    color: i == widget.selectedIndex
                        ? d.accentBlue
                        : d.textSecondary,
                  ),
                ),
                trailing: widget.navItems[i].badge != null && widget.navItems[i].badge! > 0
                    ? Chip(label: Text('${widget.navItems[i].badge}'))
                    : null,
                onTap: () {
                  widget.onNavSelected(i);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = context.dash;
    final user = ref.watch(authStateProvider).maybeWhen(
          data: (u) => u,
          orElse: () => null,
        );
    final email = user?.email ?? '';
    final initials = _initialsFromUser(user?.displayName, email);

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 720;
        return ColoredBox(
          color: d.bgPrimary,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                DashboardSidebar(
                  items: widget.navItems,
                  selectedIndex: widget.selectedIndex,
                  onSelect: widget.onNavSelected,
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DashboardTopBar(
                      showMenuButton: !wide,
                      onMenuTap: wide ? null : _openMobileNav,
                      onAddListing: widget.onAddListing,
                      searchController: _searchCtrl,
                      userInitials: initials,
                      onSettings: widget.onSettings,
                      onSignOut: widget.onSignOut,
                      themeToggle: const ThemeModeCycleButton(),
                    ),
                    Expanded(
                      child: Scaffold(
                        backgroundColor: Colors.transparent,
                        body: Material(
                          color: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                            child: widget.child,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _initialsFromUser(String? displayName, String email) {
  final n = (displayName ?? '').trim();
  if (n.isNotEmpty) {
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return n.length >= 2 ? n.substring(0, 2).toUpperCase() : '${n}X'.substring(0, 2).toUpperCase();
  }
  final local = email.split('@').first;
  if (local.length >= 2) return local.substring(0, 2).toUpperCase();
  if (local.isNotEmpty) return local.substring(0, 1).toUpperCase();
  return 'KA';
}