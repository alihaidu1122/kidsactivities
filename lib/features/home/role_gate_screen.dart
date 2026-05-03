import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/user_profile_providers.dart';
import '../profile/user_role.dart';
import '../dashboards/admin_dashboard.dart';
import '../dashboards/parent_dashboard.dart';
import '../dashboards/provider_dashboard.dart';

class RoleGateScreen extends ConsumerWidget {
  const RoleGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);
    return roleAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load role.\n$e'),
          ),
        ),
      ),
      data: (role) {
        return switch (role) {
          UserRole.parent => const ParentDashboard(),
          UserRole.provider => const ProviderDashboard(),
          UserRole.admin => const AdminDashboard(),
          UserRole.unknown => const _NoRoleScreen(),
        };
      },
    );
  }
}

class _NoRoleScreen extends StatelessWidget {
  const _NoRoleScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Your account has no role yet.\n\nAn admin must assign parent/provider/admin.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

