import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../profile/user_profile_providers.dart';
import '../provider/create_activity_screen.dart';
import '../provider/provider_activities_screen.dart';
import '../provider/provider_analytics_screen.dart';
import '../provider/provider_inbox_screen.dart';
import '../profile/role_profile_screen.dart';
import '../settings/settings_screen.dart';
import 'provider_dashboard_overview.dart';
import 'widgets/dashboard_shell.dart';
import 'widgets/dashboard_sidebar.dart';

class ProviderDashboard extends ConsumerStatefulWidget {
  const ProviderDashboard({super.key});

  @override
  ConsumerState<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends ConsumerState<ProviderDashboard> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authControllerProvider);
    final user = ref.watch(authStateProvider).maybeWhen(data: (u) => u, orElse: () => null);
    final db = ref.watch(firestoreProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db
          .collection('inquiries')
          .where('providerUserId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'new')
          .snapshots(),
      builder: (context, newSnap) {
        var unread = newSnap.data?.docs.length ?? 0;
        if (newSnap.hasError) {
          unread = 0;
        }
        final navItems = [
          const DashboardNavItemData(emoji: '⊞', label: 'Dashboard'),
          const DashboardNavItemData(emoji: '📋', label: 'My Listings'),
          DashboardNavItemData(
            emoji: '💬',
            label: 'Inquiries',
            badge: unread > 0 ? unread : null,
          ),
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
              ProviderDashboardOverview(
                onViewInquiries: () => setState(() => _idx = 2),
              ),
              const ProviderActivitiesScreen(),
              const ProviderInboxScreen(),
              const ProviderAnalyticsScreen(),
              const RoleProfileScreen(),
            ],
          ),
        );
      },
    );
  }
}
