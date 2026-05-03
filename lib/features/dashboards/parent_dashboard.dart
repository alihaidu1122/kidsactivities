import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../activities/activities_screen.dart';
import '../inquiries/my_inquiries_screen.dart';
import '../settings/settings_screen.dart';
import 'dashboard_scaffold.dart';

class ParentDashboard extends ConsumerStatefulWidget {
  const ParentDashboard({super.key});

  @override
  ConsumerState<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends ConsumerState<ParentDashboard> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authControllerProvider);

    return DashboardScaffold(
      title: 'Parent',
      destinations: const [
        NavigationDestination(icon: Icon(Icons.search), label: 'Activities'),
        NavigationDestination(icon: Icon(Icons.mail_outline), label: 'Inquiries'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      selectedIndex: _idx,
      onSelect: (i) => setState(() => _idx = i),
      body: Stack(
        children: [
          IndexedStack(
            index: _idx,
            children: const [
              ActivitiesScreen(),
              MyInquiriesScreen(),
              _StubScreen(title: 'My profile + children'),
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

