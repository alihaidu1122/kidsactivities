import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.when(
      data: (u) => u,
      loading: () => null,
      error: (err, st) => null,
    );
    final auth = ref.read(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kids Activities'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            user == null
                ? (authAsync.isLoading
                    ? 'Loading…'
                    : authAsync.hasError
                        ? 'Auth error'
                        : 'Not signed in')
                : 'Signed in as ${user.email ?? user.uid}.\n\nNext: role-based routing + activities feed.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

