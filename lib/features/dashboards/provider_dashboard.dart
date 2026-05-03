import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../provider/provider_activities_screen.dart';
import '../provider/provider_inbox_screen.dart';
import '../provider/provider_home_dashboard_screen.dart';
import '../settings/settings_screen.dart';
import 'dashboard_scaffold.dart';

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

    return DashboardScaffold(
      title: 'Provider',
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.event_note), label: 'Listings'),
        NavigationDestination(icon: Icon(Icons.inbox_outlined), label: 'Inquiries'),
        NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Analytics'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      selectedIndex: _idx,
      onSelect: (i) => setState(() => _idx = i),
      body: Stack(
        children: [
          IndexedStack(
            index: _idx,
            children: [
              ProviderHomeDashboardScreen(
                onViewAllInquiries: () => setState(() => _idx = 2),
              ),
              const ProviderActivitiesScreen(),
              const ProviderInboxScreen(),
              const _StubScreen(title: 'Basic analytics (views, inquiries)'),
              const _StubScreen(title: 'Business profile'),
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

