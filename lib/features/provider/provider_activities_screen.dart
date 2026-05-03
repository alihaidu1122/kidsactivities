import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../profile/user_profile_providers.dart';
import '../activities/activity.dart';
import 'create_activity_screen.dart';

final _providerListingsFilterProvider =
    NotifierProvider<_ProviderListingsFilterController, String>(_ProviderListingsFilterController.new);

class _ProviderListingsFilterController extends Notifier<String> {
  @override
  String build() => 'all'; // all|active|draft
  void set(String v) => state = v;
}

class ProviderActivitiesScreen extends ConsumerWidget {
  const ProviderActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const Center(child: Text('Not signed in'));

    final db = ref.watch(firestoreProvider);
    final q = db
        .collection('activities')
        .where('providerUserId', isEqualTo: user.uid)
        .orderBy('updatedAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final filter = ref.watch(_providerListingsFilterProvider);
        final allItems = snap.data!.docs.map(Activity.fromDoc).toList();
        final items = allItems.where((a) {
          return switch (filter) {
            'active' => a.isActive == true,
            'draft' => a.isActive == false,
            _ => true,
          };
        }).toList();

        final activeCount = allItems.where((a) => a.isActive == true).length;
        final draftCount = allItems.where((a) => a.isActive == false).length;

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ListingsHeader(
                  totalCount: allItems.length,
                  activeCount: activeCount,
                  draftCount: draftCount,
                  filter: filter,
                  onFilter: (v) => ref.read(_providerListingsFilterProvider.notifier).set(v),
                  onCreate: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreateActivityScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: items.isEmpty
                      ? const _EmptyListings()
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width >= 1200
                                ? 3
                                : width >= 840
                                    ? 2
                                    : 1;
                            return GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: crossAxisCount == 1 ? 1.55 : 0.92,
                              ),
                              itemCount: items.length + 1,
                              itemBuilder: (context, i) {
                                if (i == items.length) {
                                  return _CreateCard(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const CreateActivityScreen()),
                                      );
                                    },
                                  );
                                }
                                return _ListingCard(activity: items[i]);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'approved':
        bg = scheme.tertiaryContainer;
        fg = scheme.onTertiaryContainer;
        break;
      case 'pending':
        bg = scheme.secondaryContainer;
        fg = scheme.onSecondaryContainer;
        break;
      case 'rejected':
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
        break;
      default:
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurfaceVariant;
    }
    return DecoratedBox(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(status, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg)),
      ),
    );
  }
}

class _ListingsHeader extends StatelessWidget {
  const _ListingsHeader({
    required this.totalCount,
    required this.activeCount,
    required this.draftCount,
    required this.filter,
    required this.onFilter,
    required this.onCreate,
  });

  final int totalCount;
  final int activeCount;
  final int draftCount;
  final String filter;
  final ValueChanged<String> onFilter;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Listings', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Manage and track your activity offerings.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (isWide)
                  FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Listing'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                ChoiceChip(
                  label: Text('All Activities ($totalCount)'),
                  selected: filter == 'all',
                  onSelected: (_) => onFilter('all'),
                ),
                ChoiceChip(
                  label: Text('Active ($activeCount)'),
                  selected: filter == 'active',
                  onSelected: (_) => onFilter('active'),
                ),
                ChoiceChip(
                  label: Text('Drafts ($draftCount)'),
                  selected: filter == 'draft',
                  onSelected: (_) => onFilter('draft'),
                ),
                if (!isWide)
                  FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add),
                    label: const Text('New Listing'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyListings extends StatelessWidget {
  const _EmptyListings();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.list_alt_outlined, size: 44, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text('No listings yet', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Create your first activity listing to reach more families.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateCard extends StatelessWidget {
  const _CreateCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: scheme.outlineVariant, style: BorderStyle.solid),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: scheme.primaryContainer.withValues(alpha: 0.35),
                  child: Icon(Icons.add, color: scheme.primary, size: 30),
                ),
                const SizedBox(height: 12),
                Text('List an Activity', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Ready to reach more families?',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingCard extends ConsumerWidget {
  const _ListingCard({required this.activity});
  final Activity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(firestoreProvider);
    final scheme = Theme.of(context).colorScheme;
    final isActive = activity.isActive;

    final statusBadge = isActive
        ? ('Active', Colors.green)
        : ('Inactive', scheme.onSurfaceVariant);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Image header placeholder (replace later with real photos[0]).
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: scheme.surfaceContainerHighest,
                  child: Icon(Icons.image_outlined, size: 52, color: scheme.onSurfaceVariant),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusBadge.$2,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            statusBadge.$1,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.title.isEmpty ? '(Untitled)' : activity.title,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ages ${activity.ageRangeMin}-${activity.ageRangeMax} • ${activity.city}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _StatusChip(status: activity.approvalStatus),
                                if (activity.approvalStatus == 'rejected' &&
                                    (activity.rejectionReason ?? '').isNotEmpty)
                                  _StatusChip(status: 'Reason: ${activity.rejectionReason}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit screen coming next.')),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete listing?'),
                              content: const Text('This cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          await db.doc('activities/${activity.id}').delete();
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.visibility_outlined,
                          label: 'Views',
                          value: '${activity.viewCount}',
                          muted: !isActive,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.chat_bubble_outline,
                          label: 'Inquiries',
                          value: '${activity.inquiryCount}',
                          highlight: true,
                          muted: !isActive,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: scheme.outlineVariant)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Listing Visibility',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                        Switch(
                          value: isActive,
                          onChanged: (v) async {
                            await db.doc('activities/${activity.id}').set(
                              {'isActive': v, 'updatedAt': FieldValue.serverTimestamp()},
                              SetOptions(merge: true),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = scheme.surfaceContainerLow;
    final fg = highlight ? scheme.primary : scheme.onSurfaceVariant;
    final opacity = muted ? 0.55 : 1.0;
    return Opacity(
      opacity: opacity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}
extension _AsyncValueOrNull<T> on AsyncValue<T> {
  T? get valueOrNull => when(data: (v) => v, loading: () => null, error: (err, st) => null);
}

