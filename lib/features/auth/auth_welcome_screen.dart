import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/auth_brand_mark.dart';

/// Landing page to pick how you sign in (parent, provider, or admin portal).
class AuthWelcomeScreen extends StatelessWidget {
  const AuthWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const AuthBrandMark(),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in to continue',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _PortalCard(
                    title: 'Parent',
                    subtitle: 'Browse activities and send inquiries',
                    icon: Icons.family_restroom_outlined,
                    onTap: () => context.go('/sign-in/parent'),
                  ),
                  const SizedBox(height: 12),
                  _PortalCard(
                    title: 'Provider',
                    subtitle: 'Manage listings and inquiries',
                    icon: Icons.storefront_outlined,
                    onTap: () => context.go('/sign-in/provider'),
                  ),
                  const SizedBox(height: 12),
                  _PortalCard(
                    title: 'Admin',
                    subtitle: 'Moderate content and users',
                    icon: Icons.admin_panel_settings_outlined,
                    onTap: () => context.go('/sign-in/admin'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PortalCard extends StatelessWidget {
  const _PortalCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
