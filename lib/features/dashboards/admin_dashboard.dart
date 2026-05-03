import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/admin_analytics_screen.dart';
import '../admin/admin_categories_screen.dart';
import '../admin/admin_inquiries_screen.dart';
import '../admin/admin_listings_manage_screen.dart';
import '../admin/admin_reviews_moderation_screen.dart';
import '../admin/admin_users_screen.dart';
import '../auth/auth_providers.dart';
import '../provider/create_activity_screen.dart';
import '../profile/role_profile_screen.dart';
import '../profile/user_profile_providers.dart';
import '../settings/settings_screen.dart';
import 'admin_dashboard_overview.dart';
import 'widgets/dashboard_shell.dart';
import 'widgets/dashboard_sidebar.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _idx = 0;
  String _listingsFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authControllerProvider);
    final db = ref.watch(firestoreProvider);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('activities').where('approvalStatus', isEqualTo: 'pending').snapshots(),
      builder: (context, pendSnap) {
        final pendingCount = pendSnap.data?.docs.length ?? 0;
        final navItems = [
          const DashboardNavItemData(emoji: '⊞', label: 'Dashboard'),
          DashboardNavItemData(
            emoji: '📋',
            label: 'Listings',
            badge: pendingCount > 0 ? pendingCount : null,
          ),
          const DashboardNavItemData(emoji: '👥', label: 'Users', trailingArrow: true),
          const DashboardNavItemData(emoji: '💬', label: 'Inquiries'),
          const DashboardNavItemData(emoji: '⭐', label: 'Reviews'),
          const DashboardNavItemData(emoji: '🏷️', label: 'Categories'),
          const DashboardNavItemData(emoji: '📊', label: 'Analytics'),
          const DashboardNavItemData(emoji: '👤', label: 'Profile'),
        ];

        return DashboardShell(
          navItems: navItems,
          selectedIndex: _idx,
          onNavSelected: (i) => setState(() => _idx = i),
          onAddListing: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateActivityScreen()),
            );
          },
          onSettings: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
          onSignOut: () async => auth.signOut(),
          child: IndexedStack(
            index: _idx,
            children: [
              AdminDashboardOverview(
                onViewPendingListings: () => setState(() {
                  _listingsFilter = 'pending';
                  _idx = 1;
                }),
                onViewAllListings: () => setState(() {
                  _listingsFilter = 'all';
                  _idx = 1;
                }),
              ),
              AdminListingsManageScreen(
                key: ValueKey(_listingsFilter),
                initialFilter: _listingsFilter,
              ),
              const AdminUsersScreen(),
              const AdminInquiriesScreen(),
              const AdminReviewsModerationScreen(),
              const AdminCategoriesScreen(),
              const AdminAnalyticsScreen(),
              const RoleProfileScreen(),
            ],
          ),
        );
      },
    );
  }
}
