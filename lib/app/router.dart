import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';

import '../features/activities/activities_screen.dart';
import '../features/activities/parent_activity_detail_screen.dart';
import '../features/auth/auth_providers.dart';
import '../features/auth/auth_welcome_screen.dart';
import '../features/auth/role_sign_in_screen.dart';
import '../features/dashboards/parent/parent_responsive_layout.dart';
import 'theme/dashboard_tokens.dart';
import '../features/home/role_gate_screen.dart';
import '../features/inquiries/my_inquiries_screen.dart';
import '../features/onboarding/parent_onboarding_screen.dart';
import '../features/profile/role_profile_screen.dart';
import '../features/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(firebaseAuthProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _GoRouterRefreshStream(
      auth.authStateChanges(),
    ),
    redirect: (context, state) {
      final user = auth.currentUser;
      final loc = state.matchedLocation;

      final isPublicAuth =
          loc == '/welcome' || loc.startsWith('/sign-in') || loc == '/join';

      if (user == null) {
        if (loc.startsWith('/parent')) return '/welcome';
        if (isPublicAuth) return null;
        return '/welcome';
      }
      if (isPublicAuth || loc == '/welcome') return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RoleGateScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const AuthWelcomeScreen(),
      ),
      GoRoute(
        path: '/sign-in/parent',
        builder: (context, state) => const RoleSignInScreen(role: AuthPortalRole.parent),
      ),
      GoRoute(
        path: '/sign-in/provider',
        builder: (context, state) => const RoleSignInScreen(role: AuthPortalRole.provider),
      ),
      GoRoute(
        path: '/sign-in/admin',
        builder: (context, state) => const RoleSignInScreen(role: AuthPortalRole.admin),
      ),
      GoRoute(
        path: '/join',
        builder: (context, state) => const ParentOnboardingScreen(),
      ),
      GoRoute(
        path: '/parent',
        redirect: (context, state) => '/parent/discover',
      ),
      // Shell must sit beside `/parent` (not nested under it) with absolute branch paths — same
      // pattern as go_router's stateful_shell_route example — so `goBranch` / URI stay in sync.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(authStateProvider).maybeWhen(orElse: () => null, data: (u) => u);
              final initials = _parentUserInitials(user);
              final authController = ref.read(authControllerProvider);
              final d = context.dash;
              return ParentResponsiveLayout(
                currentIndex: navigationShell.currentIndex,
                onNavTap: navigationShell.goBranch,
                userInitials: initials,
                onMenuPressed: () => _openParentOverflowMenu(
                  context: context,
                  d: d,
                  authController: authController,
                ),
                child: navigationShell,
              );
            },
          );
        },
        branches: [
          StatefulShellBranch(
            initialLocation: '/parent/discover',
            routes: [
              GoRoute(
                path: '/parent/discover',
                builder: (context, state) => const ActivitiesScreen(),
                routes: [
                  GoRoute(
                    path: 'activity/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return ParentActivityDetailScreen(activityId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: '/parent/inquiries',
            preload: true,
            routes: [
              GoRoute(
                path: '/parent/inquiries',
                builder: (context, state) => const MyInquiriesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: '/parent/profile',
            preload: true,
            routes: [
              GoRoute(
                path: '/parent/profile',
                builder: (context, state) => const RoleProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

Future<void> _openParentOverflowMenu({
  required BuildContext context,
  required DashboardTokens d,
  required AuthController authController,
}) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: d.bgSecondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.settings_outlined, color: d.textPrimary),
            title: Text('Settings', style: TextStyle(color: d.textPrimary)),
            onTap: () => Navigator.pop(ctx, 'settings'),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: d.textPrimary),
            title: Text('Sign out', style: TextStyle(color: d.textPrimary)),
            onTap: () => Navigator.pop(ctx, 'logout'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  if (action == 'settings') {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }
  if (action == 'logout') {
    await authController.signOut();
  }
}

String _parentUserInitials(User? user) {
  if (user == null) return '?';
  final dn = user.displayName?.trim();
  if (dn != null && dn.isNotEmpty) {
    final parts = dn.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (dn.length >= 2) return dn.substring(0, 2).toUpperCase();
    return dn[0].toUpperCase();
  }
  final email = user.email?.trim();
  if (email != null && email.length >= 2) {
    return email.substring(0, 2).toUpperCase();
  }
  return 'U';
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<User?> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
