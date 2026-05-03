import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../inquiries/inquiry.dart';
import '../profile/user_profile_providers.dart';
import 'create_activity_screen.dart';

class ProviderHomeDashboardScreen extends ConsumerWidget {
  const ProviderHomeDashboardScreen({
    super.key,
    required this.onViewAllInquiries,
  });

  final VoidCallback onViewAllInquiries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.when(
      data: (u) => u,
      loading: () => null,
      error: (e, st) => null,
    );
    if (user == null) {
      return auth.when(
        data: (_) => const Center(child: Text('Not signed in')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Auth error: $e')),
      );
    }

    final db = ref.watch(firestoreProvider);
    final activitiesQ = db.collection('activities').where('providerUserId', isEqualTo: user.uid);
    final inquiriesQ = db
        .collection('inquiries')
        .where('providerUserId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(5);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopHeader(
            providerName: user.email ?? 'Provider',
            onAddListing: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateActivityScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: activitiesQ.snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const _StatsGridSkeleton();
                    }
                    final docs = snap.data!.docs;
                    final activeListings = docs.where((d) => (d.data()['isActive'] as bool?) == true).length;
                    int totalViews = 0;
                    int totalInquiries = 0;
                    for (final d in docs) {
                      totalViews += ((d.data()['viewCount'] as num?)?.toInt() ?? 0);
                      totalInquiries += ((d.data()['inquiryCount'] as num?)?.toInt() ?? 0);
                    }
                    return _StatsGrid(
                      totalViews: totalViews,
                      totalInquiries: totalInquiries,
                      activeListings: activeListings,
                    );
                  },
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: inquiriesQ.snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const _RecentInquiriesCard(loading: true, inquiries: []);
                    }
                    final inquiries = snap.data!.docs.map(Inquiry.fromDoc).toList();
                    return _RecentInquiriesCard(
                      loading: false,
                      inquiries: inquiries,
                      onViewAll: onViewAllInquiries,
                    );
                  },
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoCol = constraints.maxWidth >= 980;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: twoCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                          child: const _EngagementCard(),
                        ),
                        SizedBox(
                          width: twoCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                          child: const _ProTipCard(),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.providerName, required this.onAddListing});
  final String providerName;
  final VoidCallback onAddListing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $providerName!',
                    style: Theme.of(context).textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Here is an overview of your activities and inquiries.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onAddListing,
              icon: const Icon(Icons.add),
              label: const Text('Add New Listing'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.totalViews,
    required this.totalInquiries,
    required this.activeListings,
  });

  final int totalViews;
  final int totalInquiries;
  final int activeListings;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 900 ? 3 : 1;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: cols == 1 ? 3.2 : 2.8,
          children: [
            _StatCard(
              icon: Icons.visibility_outlined,
              title: 'Total Views',
              value: totalViews.toString(),
              tint: Theme.of(context).colorScheme.primary,
            ),
            _StatCard(
              icon: Icons.forum_outlined,
              title: 'Total Inquiries',
              value: totalInquiries.toString(),
              tint: Theme.of(context).colorScheme.secondary,
            ),
            _StatCard(
              icon: Icons.checklist_outlined,
              title: 'Active Listings',
              value: activeListings.toString(),
              tint: Theme.of(context).colorScheme.tertiary,
            ),
          ],
        );
      },
    );
  }
}

class _StatsGridSkeleton extends StatelessWidget {
  const _StatsGridSkeleton();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()));
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.title, required this.value, required this.tint});
  final IconData icon;
  final String title;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 28, color: tint),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentInquiriesCard extends StatelessWidget {
  const _RecentInquiriesCard({
    this.onViewAll,
    required this.loading,
    required this.inquiries,
  });

  final VoidCallback? onViewAll;
  final bool loading;
  final List<Inquiry> inquiries;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('Recent Inquiries', style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(alignment: Alignment.centerLeft, child: CircularProgressIndicator()),
            )
          else if (inquiries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(alignment: Alignment.centerLeft, child: Text('No inquiries yet.')),
            )
          else
            ...inquiries.map((q) => _InquiryRow(inquiry: q)),
        ],
      ),
    );
  }
}

class _InquiryRow extends StatelessWidget {
  const _InquiryRow({required this.inquiry});
  final Inquiry inquiry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = (inquiry.parentName.trim().isEmpty ? '?' : inquiry.parentName.trim())
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    final badge = switch (inquiry.status) {
      'new' => ('Pending', scheme.tertiaryContainer, scheme.onTertiaryContainer),
      'responded' => ('Replied', scheme.secondaryContainer, scheme.onSecondaryContainer),
      'closed' => ('Closed', scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      _ => (inquiry.status, scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };

    return InkWell(
      onTap: null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primaryContainer.withValues(alpha: 0.35),
              child: Text(initials, style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inquiry.parentName.isEmpty ? '(No name)' : inquiry.parentName,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '${inquiry.activityId} • ${_relativeTime(inquiry.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(color: badge.$2, borderRadius: BorderRadius.circular(999)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(badge.$1, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: badge.$3)),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _EngagementCard extends StatelessWidget {
  const _EngagementCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      child: Container(
        height: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.35),
              scheme.surface,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Engagement', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Listing views are trending upward. Keep updating your content!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                8,
                (i) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Container(
                      height: 30.0 + (i * 10.0),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProTipCard extends StatelessWidget {
  const _ProTipCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      child: Container(
        height: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: scheme.secondaryContainer.withValues(alpha: 0.35),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.lightbulb_outline, color: scheme.secondary),
            ),
            const SizedBox(height: 12),
            Text('Pro Tip', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Adding high-quality photos can significantly increase inquiries.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Edit listing'),
            ),
          ],
        ),
      ),
    );
  }
}

String _relativeTime(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

