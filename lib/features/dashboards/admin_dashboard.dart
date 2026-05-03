import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../admin/admin_activity_moderation_screen.dart';
import '../admin/admin_categories_screen.dart';
import '../admin/admin_tools_screen.dart';
import '../settings/settings_screen.dart';
import 'dashboard_scaffold.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authControllerProvider);

    return DashboardScaffold(
      title: 'Admin',
      destinations: const [
        NavigationDestination(icon: Icon(Icons.group_outlined), label: 'Users'),
        NavigationDestination(icon: Icon(Icons.event_available_outlined), label: 'Activities'),
        NavigationDestination(icon: Icon(Icons.category_outlined), label: 'Categories'),
        NavigationDestination(icon: Icon(Icons.reviews_outlined), label: 'Reviews'),
      ],
      selectedIndex: _idx,
      onSelect: (i) => setState(() => _idx = i),
      body: Stack(
        children: [
          IndexedStack(
            index: _idx,
            children: const [
              AdminToolsScreen(),
              AdminActivityModerationScreen(),
              AdminCategoriesScreen(),
              _StubScreen(title: 'Moderate reviews (approve/flag/delete)'),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final action = await showModalBottomSheet<String>(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.settings),
                          title: const Text('Settings'),
                          onTap: () => Navigator.pop(context, 'settings'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Sign out'),
                          onTap: () => Navigator.pop(context, 'logout'),
                        ),
                      ],
                    ),
                  ),
                );
                if (!mounted) return;
                if (action == 'settings') {
                  navigator.push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                }
                if (action == 'logout') {
                  await auth.signOut();
                }
              },
              icon: const Icon(Icons.more_horiz),
              label: const Text('Menu'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StubScreen extends StatelessWidget {
  const _StubScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          title,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

