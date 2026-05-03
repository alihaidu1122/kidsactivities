import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';

import '../features/auth/auth_providers.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/home/role_gate_screen.dart';
import '../features/onboarding/parent_onboarding_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _GoRouterRefreshStream(
      ref.watch(firebaseAuthProvider).authStateChanges(),
    ),
    redirect: (context, state) {
      final user = authAsync.when(
        data: (u) => u,
        loading: () => null,
        error: (err, st) => null,
      );
      final isAuthRoute = state.matchedLocation == '/sign-in' || state.matchedLocation == '/join';

      if (user == null) return isAuthRoute ? null : '/sign-in';
      if (isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RoleGateScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/join',
        builder: (context, state) => const ParentOnboardingScreen(),
      ),
    ],
  );
});

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

