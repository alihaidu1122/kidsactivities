import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/dashboard_text_styles.dart';
import '../../../app/theme/dashboard_tokens.dart';
import '../../activities/activity_providers.dart';
import '../../activities/discover_filters_panel.dart';
import '../widgets/theme_mode_cycle_button.dart';
import 'parent_nav.dart';

/// Single adaptive shell: [&lt; 600] bottom nav + mobile app bar + optional FAB; [≥ 600] sidebar + dashboard-style top bar.
class ParentResponsiveLayout extends ConsumerStatefulWidget {
  const ParentResponsiveLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavTap,
    required this.userInitials,
    this.onMenuPressed,
  });

  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onNavTap;
  final String userInitials;
  final Future<void> Function()? onMenuPressed;

  @override
  ConsumerState<ParentResponsiveLayout> createState() => _ParentResponsiveLayoutState();
}

class _ParentResponsiveLayoutState extends ConsumerState<ParentResponsiveLayout> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    final q = ref.read(activityFiltersProvider).query;
    _searchCtrl = TextEditingController(text: q ?? '');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openFilterSheet() async {
    final d = context.dash;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: d.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: SingleChildScrollView(
            child: DiscoverFiltersPanel(compactHorizontal: false, densePills: true),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activityFiltersProvider, (prev, next) {
      if (prev?.query == next.query) return;
      final t = next.query ?? '';
      if (_searchCtrl.text != t) {
        _searchCtrl.value = TextEditingValue(
          text: t,
          selection: TextSelection.collapsed(offset: t.length),
        );
      }
    });

    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < parentNavBreakpoint;
    final d = context.dash;
    final title = parentTitleForIndex(widget.currentIndex);
    // matchedLocation from GoRouterState.of(context) is scoped under the shell — use full URI path.
    final path = GoRouter.of(context).state.uri.path;
    final isDetailRoute = path.contains('/activity/');

    if (isMobile) {
      return _MobileLayout(
        d: d,
        title: title,
        currentIndex: widget.currentIndex,
        onNavTap: widget.onNavTap,
        onMenuPressed: widget.onMenuPressed,
        showFilterFab: widget.currentIndex == 0 && !isDetailRoute,
        onFilterFab: _openFilterSheet,
        isDetailRoute: isDetailRoute,
        themeToggle: const ThemeModeCycleButton(),
        child: widget.child,
      );
    }

    return _WebLayout(
      d: d,
      currentIndex: widget.currentIndex,
      onNavTap: widget.onNavTap,
      searchController: _searchCtrl,
      onSearchChanged: (v) => ref.read(activityFiltersProvider.notifier).setSearchQuery(v),
      userInitials: widget.userInitials,
      onMenuPressed: widget.onMenuPressed,
      pageTitle: title,
      isDetailRoute: isDetailRoute,
      themeToggle: const ThemeModeCycleButton(),
      child: widget.child,
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.d,
    required this.title,
    required this.currentIndex,
    required this.onNavTap,
    required this.child,
    this.onMenuPressed,
    this.showFilterFab = false,
    this.onFilterFab,
    this.isDetailRoute = false,
    this.themeToggle,
  });

  final DashboardTokens d;
  final String title;
  final int currentIndex;
  final ValueChanged<int> onNavTap;
  final Widget child;
  final Future<void> Function()? onMenuPressed;
  final bool showFilterFab;
  final VoidCallback? onFilterFab;
  final bool isDetailRoute;
  final Widget? themeToggle;

  @override
  Widget build(BuildContext context) {
    if (isDetailRoute) {
      return Scaffold(
        backgroundColor: d.bgPrimary,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: child,
        ),
      );
    }

    return Scaffold(
      backgroundColor: d.bgPrimary,
      appBar: AppBar(
        backgroundColor: d.bgSecondary,
        foregroundColor: d.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: d.borderColor),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'KiddoMarket',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: d.accentBlue,
                letterSpacing: 0.05,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: d.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          if (themeToggle != null) themeToggle!,
          IconButton(
            icon: Icon(Icons.more_vert, color: d.textMuted),
            onPressed: onMenuPressed == null
                ? null
                : () {
                    onMenuPressed!();
                  },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: child,
      ),
      floatingActionButton: showFilterFab
          ? SizedBox(
              width: 44,
              height: 44,
              child: FloatingActionButton(
                onPressed: onFilterFab,
                backgroundColor: d.accentBlue,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.tune_rounded, size: 22),
              ),
            )
          : null,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: d.bgSecondary,
            border: Border(top: BorderSide(color: d.borderColor, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final item in parentNavItems)
                _BottomNavItem(
                  item: item,
                  isActive: item.index == currentIndex,
                  d: d,
                  onTap: () => onNavTap(item.index),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.item,
    required this.isActive,
    required this.d,
    required this.onTap,
  });

  final ParentNavItem item;
  final bool isActive;
  final DashboardTokens d;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 28,
                decoration: BoxDecoration(
                  color: isActive ? d.accentBlue.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(item.icon, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? d.accentBlue : d.textFaint,
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

class _WebLayout extends StatelessWidget {
  const _WebLayout({
    required this.d,
    required this.currentIndex,
    required this.onNavTap,
    required this.searchController,
    required this.onSearchChanged,
    required this.userInitials,
    required this.child,
    required this.pageTitle,
    this.onMenuPressed,
    this.isDetailRoute = false,
    this.themeToggle,
  });

  final DashboardTokens d;
  final int currentIndex;
  final ValueChanged<int> onNavTap;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String userInitials;
  final Widget child;
  final String pageTitle;
  final Future<void> Function()? onMenuPressed;
  final bool isDetailRoute;
  final Widget? themeToggle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: d.bgPrimary,
      appBar: isDetailRoute
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(54),
              child: Material(
                color: d.bgSecondary,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: d.borderColor)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      if (currentIndex == 0)
                        Expanded(
                          flex: 2,
                          child: ConstrainedBox(
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
                                hintText: 'Search activities…',
                                hintStyle: DashboardTextStyles.label(d).copyWith(color: d.textFaint),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 8, right: 4),
                                  child: Center(widthFactor: 1, child: Text('🔍', style: TextStyle(fontSize: 13))),
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
                        )
                      else
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              pageTitle,
                              style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: d.textPrimary),
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (themeToggle != null) themeToggle!,
                      IconButton(
                        icon: Icon(Icons.notifications_none_rounded, color: d.textMuted, size: 22),
                        onPressed: () {},
                        tooltip: 'Notifications',
                      ),
                      const SizedBox(width: 4),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: d.accentBlue,
                        child: Text(
                          userInitials.length > 2 ? userInitials.substring(0, 2) : userInitials,
                          style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.more_vert, color: d.textMuted),
                        onPressed: onMenuPressed == null ? null : () => onMenuPressed!(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 200,
            child: ColoredBox(
              color: d.bgSecondary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SidebarHeader(d: d),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(8),
                      children: [
                        for (final item in parentNavItems)
                          _SidebarNavItem(
                            item: item,
                            isActive: item.index == currentIndex,
                            d: d,
                            onTap: () => onNavTap(item.index),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: d.borderColor),
          Expanded(
            child: ColoredBox(
              color: d.bgPrimary,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.d});
  final DashboardTokens d;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: d.borderColor)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('🎯', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
              children: [
                TextSpan(text: 'Kids', style: TextStyle(color: d.textPrimary)),
                TextSpan(text: 'Hub', style: TextStyle(color: d.accentBlue)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.item,
    required this.isActive,
    required this.d,
    required this.onTap,
  });

  final ParentNavItem item;
  final bool isActive;
  final DashboardTokens d;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isActive ? d.accentBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          hoverColor: d.bgTertiary,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Text(item.icon, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 10),
                Text(
                  item.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.white : d.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
