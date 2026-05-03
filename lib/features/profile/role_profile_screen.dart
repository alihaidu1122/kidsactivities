import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/widgets/role_gate_loading.dart';
import 'admin_profile_screen.dart';
import 'parent_profile_screen.dart';
import 'provider_profile_screen.dart';
import 'user_profile_providers.dart';
import 'user_role.dart';

/// Routes to the profile layout for the signed-in role (parent / provider / admin).
class RoleProfileScreen extends ConsumerWidget {
  const RoleProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);

    return roleAsync.when(
      loading: () => const RoleGateLoadingBody(),
      error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load role.\n$e'))),
      data: (role) {
        return switch (role) {
          UserRole.parent => const ParentProfileScreen(),
          UserRole.provider => const ProviderProfileScreen(),
          UserRole.admin => const AdminProfileScreen(),
          UserRole.unknown => const ParentProfileScreen(),
        };
      },
    );
  }
}
