import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/user_profile_providers.dart';
import '../profile/user_role.dart';
import '../auth/auth_providers.dart';
import '../dashboards/admin_dashboard.dart';
import '../dashboards/parent/parent_app_redirect.dart';
import '../dashboards/provider_dashboard.dart';
import 'widgets/role_gate_loading.dart';

class RoleGateScreen extends ConsumerWidget {
  const RoleGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).maybeWhen(data: (u) => u, orElse: () => null);
    if (user == null) {
      return const RoleGateLoadingScaffold();
    }

    final roleAsync = ref.watch(userRoleProvider);
    return roleAsync.when(
      loading: () => const RoleGateLoadingScaffold(),
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
          UserRole.parent => const ParentAppShellRedirect(),
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
