import 'package:flutter/material.dart';

/// Breakpoint: below = mobile bottom nav, at/above = web sidebar.
const double parentNavBreakpoint = 600;

@immutable
class ParentNavItem {
  const ParentNavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.route,
  });

  final int index;
  final String icon;
  final String label;
  final String route;
}

const List<ParentNavItem> parentNavItems = [
  ParentNavItem(index: 0, icon: '🧭', label: 'Discover', route: '/parent/discover'),
  ParentNavItem(index: 1, icon: '💬', label: 'Inquiries', route: '/parent/inquiries'),
  ParentNavItem(index: 2, icon: '👤', label: 'Profile', route: '/parent/profile'),
];

String parentTitleForIndex(int index) {
  return switch (index) {
    1 => 'Inquiries',
    2 => 'Profile',
    _ => 'Discover',
  };
}

/// Scrollable list bottom inset: mobile accounts for bottom nav + safe area.
double parentContentBottomPadding(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return w < parentNavBreakpoint ? 80 + MediaQuery.paddingOf(context).bottom : 20;
}
