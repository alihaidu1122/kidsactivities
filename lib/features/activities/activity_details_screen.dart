import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../inquiries/create_inquiry_screen.dart';
import '../reviews/review_providers.dart';
import 'activity.dart';

class ActivityDetailsScreen extends ConsumerStatefulWidget {
  const ActivityDetailsScreen({super.key, required this.activity});

  final Activity activity;

  @override
  ConsumerState<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends ConsumerState<ActivityDetailsScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    // Placeholder images for now (until we wire Storage/photos field into Activity model).
    final images = const <String>[
      'https://images.unsplash.com/photo-1527102847068-818daae1f46d?auto=format&fit=crop&w=1600&q=80',
      'https://images.unsplash.com/photo-1523413651479-597eb2da0ad6?auto=format&fit=crop&w=1600&q=80',
      'https://images.unsplash.com/photo-1517602302552-471fe67acf66?auto=format&fit=crop&w=1600&q=80',
    ];

    final price = a.priceAmount == null ? null : '€${a.priceAmount}';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
            ),
            title: const Text('KiddoMarket Estonia'),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
              const SizedBox(width: 6),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroCarousel(
                        images: images,
                        page: _page,
                        onPage: (v) => setState(() => _page = v),
                      ),
                      const SizedBox(height: 16),
                      _HeaderInfo(
                        activity: a,
                        price: price,
                        showDesktopBook: isWide,
                        onBook: () {},
                      ),
                      const SizedBox(height: 16),
                      _BentoInfoGrid(activity: a),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, c) {
                          final twoCol = c.maxWidth >= 980;
                          if (!twoCol) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _LeftColumn(activity: a),
                                const SizedBox(height: 16),
                                _RightColumn(activity: a),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _LeftColumn(activity: a)),
                              const SizedBox(width: 16),
                              SizedBox(width: 360, child: _RightColumn(activity: a)),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Divider(height: 1, color: scheme.outlineVariant),
                      const SizedBox(height: 18),
                      _ReviewsSection(activityId: a.id),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : SafeArea(
              top: false,
              child: Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.92),
                  border: Border(top: BorderSide(color: scheme.outlineVariant)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total', style: Theme.of(context).textTheme.labelSmall),
                          Text(
                            price ?? '—',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
                      child: const Text('Book Now'),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: isWide
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateInquiryScreen(activity: a)));
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Contact'),
            ),
    );
  }
}

class _HeroCarousel extends StatelessWidget {
  const _HeroCarousel({required this.images, required this.page, required this.onPage});

  final List<String> images;
  final int page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: MediaQuery.sizeOf(context).width >= 768 ? 21 / 9 : 4 / 3,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: images.length,
              onPageChanged: onPage,
              itemBuilder: (context, i) => Image.network(images[i], fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) {
                  final active = i == page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? scheme.primary : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  const _HeaderInfo({
    required this.activity,
    required this.price,
    required this.showDesktopBook,
    required this.onBook,
  });

  final Activity activity;
  final String? price;
  final bool showDesktopBook;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text('Most Popular', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900)),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 18, color: Colors.amber.shade600),
                      const SizedBox(width: 4),
                      Text('4.9', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(width: 6),
                      Text('(124 reviews)', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                activity.title.isEmpty ? 'Activity' : activity.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🎨', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activity.providerBusinessName ?? 'Provider', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.verified, size: 16, color: scheme.secondary),
                            const SizedBox(width: 6),
                            Text('Verified Provider', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.secondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDesktopBook) ...[
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Starting from', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(
                price ?? '—',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: onBook,
                style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
                child: const Text('Book a Spot'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BentoInfoGrid extends StatelessWidget {
  const _BentoInfoGrid({required this.activity});
  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Age Range', '${activity.ageRangeMin}-${activity.ageRangeMax} Years', Icons.child_care),
      ('Duration', '90 Minutes', Icons.schedule),
      ('Class Size', 'Max 8 Kids', Icons.group),
      ('Language', 'EE / EN / RU', Icons.language),
    ];
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width >= 768 ? 4 : 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final it in items)
          _InfoTile(title: it.$1, value: it.$2, icon: it.$3),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: scheme.secondary),
            ),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.labelLarge, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _LeftColumn extends StatelessWidget {
  const _LeftColumn({required this.activity});
  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('About the activity', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(activity.description.isEmpty ? 'No description provided.' : activity.description, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 14),
        Wrap(
          runSpacing: 10,
          spacing: 16,
          children: const [
            _CheckLine(text: 'Materials included'),
            _CheckLine(text: 'Non‑toxic materials'),
            _CheckLine(text: 'Aprons provided'),
            _CheckLine(text: 'Take home your work'),
          ],
        ),
        const SizedBox(height: 22),
        Text('Where we are', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 250,
            color: scheme.surfaceContainerHighest,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.55,
                    child: Image.network(
                      'https://images.unsplash.com/photo-1526779259212-939e64788e3b?auto=format&fit=crop&w=1600&q=80',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Center(
                  child: CircleAvatar(
                    radius: 26,
                    child: Icon(Icons.location_on),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.near_me),
            title: Text(activity.city),
            subtitle: const Text('Address details coming from provider listing.'),
          ),
        ),
      ],
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _RightColumn extends StatelessWidget {
  const _RightColumn({required this.activity});
  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProviderCard(activity: activity),
        const SizedBox(height: 12),
        _NextSessionsCard(activity: activity),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.activity});
  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: scheme.surfaceContainerHighest,
                    child: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.providerBusinessName ?? 'Provider', style: Theme.of(context).textTheme.titleMedium),
                      Text('Verified Provider', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '"I love seeing the magic happen when children first feel the clay take shape in their hands."',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateInquiryScreen(activity: activity)));
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Contact Provider'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextSessionsCard extends StatelessWidget {
  const _NextSessionsCard({required this.activity});
  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Next Sessions', style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 1.1, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            _SessionRow(date: 'Sat, Oct 12', time: '10:00 - 11:30', status: 'AVAILABLE', ok: true),
            const SizedBox(height: 10),
            _SessionRow(date: 'Sun, Oct 13', time: '14:00 - 15:30', status: 'FULL', ok: false),
          ],
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.date, required this.time, required this.status, required this.ok});
  final String date;
  final String time;
  final String status;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = ok ? Colors.green.shade100 : Colors.red.shade100;
    final fg = ok ? Colors.green.shade800 : Colors.red.shade800;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: Theme.of(context).textTheme.labelLarge),
                Text(time, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(status, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.activityId});
  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final reviewsAsync = ref.watch(activityApprovedReviewsProvider(activityId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Community Reviews', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write review coming next.')));
              },
              child: const Text('Write a review'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        reviewsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, st) => Text('Failed to load reviews: $e'),
          data: (items) {
            if (items.isEmpty) {
              return const Text('No reviews yet.');
            }
            final cols = MediaQuery.sizeOf(context).width >= 768 ? 2 : 1;
            return Column(
              children: [
                GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: cols == 2 ? 2.1 : 2.4,
                  children: [
                    for (final r in items) _ReviewCard(r: r),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('View All Reviews'),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Only approved reviews are visible publicly.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.r});
  final dynamic r;

  @override
  Widget build(BuildContext context) {
    final review = r as dynamic;
    final scheme = Theme.of(context).colorScheme;
    final initials = (review.parentName as String)
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.tertiaryContainer.withValues(alpha: 0.55),
                  child: Text(initials, style: TextStyle(color: scheme.onTertiaryContainer, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.parentName as String, style: Theme.of(context).textTheme.labelLarge),
                      Text('Verified parent', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                _Stars(rating: (review.rating as int).clamp(0, 5)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              (review.reviewText as String?)?.trim().isEmpty ?? true ? 'Great experience!' : (review.reviewText as String).trim(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});
  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return Icon(filled ? Icons.star : Icons.star_border, size: 16, color: Colors.amber.shade600);
      }),
    );
  }
}

