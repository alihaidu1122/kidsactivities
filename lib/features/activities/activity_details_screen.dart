import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/dashboard_text_styles.dart';
import '../../app/theme/dashboard_tokens.dart';
import '../inquiries/create_inquiry_screen.dart';
import '../reviews/review.dart';
import '../reviews/review_providers.dart';
import 'activity.dart';
import 'activity_media.dart';
import 'widgets/activity_network_image.dart';

class ActivityDetailsScreen extends ConsumerStatefulWidget {
  const ActivityDetailsScreen({super.key, required this.activity});

  final Activity activity;

  @override
  ConsumerState<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends ConsumerState<ActivityDetailsScreen> {
  int _page = 0;

  static String _priceGridLine(String? price, String? subtitle) {
    if (price == null) return 'Ask provider';
    if (subtitle == null || subtitle.isEmpty) return price;
    return '$price · $subtitle';
  }

  Future<void> _openInquiry() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CreateInquiryScreen(activity: widget.activity)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    final d = context.dash;
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    final listingImages = <String>[
      for (final u in a.photoUrls)
        if (sanitizeImageHttpUrl(u) case final s?) s,
    ];
    final thumb = sanitizeImageHttpUrl(a.thumbnailUrl);
    if (thumb != null && !listingImages.contains(thumb)) {
      listingImages.insert(0, thumb);
    }
    final images = listingImages.isNotEmpty
        ? listingImages
        : const <String>[
            'https://images.unsplash.com/photo-1527102847068-818daae1f46d?auto=format&fit=crop&w=1600&q=80',
            'https://images.unsplash.com/photo-1523413651479-597eb2da0ad6?auto=format&fit=crop&w=1600&q=80',
            'https://images.unsplash.com/photo-1517602302552-471fe67acf66?auto=format&fit=crop&w=1600&q=80',
          ];

    final price = a.priceAmount == null ? null : '€${a.priceAmount}';
    final priceSubtitle = a.priceType?.trim().isNotEmpty == true ? a.priceType!.trim() : null;

    return Scaffold(
      backgroundColor: d.bgPrimary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: d.bgSecondary,
            foregroundColor: d.textPrimary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: d.borderColor),
            ),
            leading: IconButton(
              onPressed: () {
                if (context.canPop()) context.pop();
              },
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: d.textMuted, size: 20),
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'KiddoMarket',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: d.accentBlue,
                    letterSpacing: 0.05,
                  ),
                ),
                Text(
                  'Activity',
                  style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: d.textPrimary),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(onPressed: () {}, icon: Icon(Icons.share_outlined, color: d.textMuted, size: 22)),
              IconButton(onPressed: () {}, icon: Icon(Icons.favorite_border_rounded, color: d.textMuted, size: 22)),
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
                      _HeroCarousel(d: d, images: images, page: _page, onPage: (v) => setState(() => _page = v)),
                      const SizedBox(height: 16),
                      _HeaderInfo(
                        d: d,
                        activity: a,
                        price: price,
                        priceSubtitle: priceSubtitle,
                        showDesktopBook: isWide,
                        onPrimaryCta: _openInquiry,
                      ),
                      const SizedBox(height: 16),
                      _BentoInfoGrid(d: d, activity: a, priceLine: _priceGridLine(price, priceSubtitle)),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, c) {
                          final twoCol = c.maxWidth >= 980;
                          if (!twoCol) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _LeftColumn(d: d, activity: a),
                                const SizedBox(height: 16),
                                _RightColumn(d: d, activity: a, onContact: _openInquiry),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _LeftColumn(d: d, activity: a)),
                              const SizedBox(width: 16),
                              SizedBox(width: 360, child: _RightColumn(d: d, activity: a, onContact: _openInquiry)),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Divider(height: 1, color: d.borderColor),
                      const SizedBox(height: 18),
                      _ReviewsSection(d: d, activityId: a.id),
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
                height: 76,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: d.bgSecondary,
                  border: Border(top: BorderSide(color: d.borderColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('From', style: DashboardTextStyles.label(d)),
                          Text(
                            price ?? 'Ask provider',
                            style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800, color: d.accentBlue),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: _openInquiry,
                      style: FilledButton.styleFrom(
                        backgroundColor: d.accentBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(168, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Contact', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: isWide
          ? null
          : FloatingActionButton.extended(
              backgroundColor: d.accentBlue,
              foregroundColor: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onPressed: _openInquiry,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
              label: Text('Contact provider', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
    );
  }
}

class _HeroCarousel extends StatelessWidget {
  const _HeroCarousel({required this.d, required this.images, required this.page, required this.onPage});

  final DashboardTokens d;
  final List<String> images;
  final int page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: MediaQuery.sizeOf(context).width >= 768 ? 21 / 9 : 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: images.length,
              onPageChanged: onPage,
              itemBuilder: (context, i) => ActivityNetworkImage(
                url: images[i],
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
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
                      color: active ? d.accentBlue : Colors.white.withValues(alpha: 0.55),
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
    required this.d,
    required this.activity,
    required this.price,
    required this.priceSubtitle,
    required this.showDesktopBook,
    required this.onPrimaryCta,
  });

  final DashboardTokens d;
  final Activity activity;
  final String? price;
  final String? priceSubtitle;
  final bool showDesktopBook;
  final Future<void> Function() onPrimaryCta;

  @override
  Widget build(BuildContext context) {
    final cat = activity.category.trim().isEmpty ? null : activity.category.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, bx) {
                  final chipMax = (bx.maxWidth - 140).clamp(100.0, 320.0);
                  final metaMax = (bx.maxWidth - chipMax - 32).clamp(72.0, 240.0);
                  return Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (cat != null)
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: chipMax),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: d.accentBlueBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: d.borderColor.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              cat,
                              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: d.roleParentText),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 18, color: d.starColor),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: metaMax,
                            child: Text(
                              activity.inquiryCount > 0 ? '${activity.inquiryCount} inquiries' : 'New listing',
                              style: DashboardTextStyles.label(d),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                activity.title.isEmpty ? 'Activity' : activity.title,
                style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w800, height: 1.2, color: d.textPrimary),
              ),
              const SizedBox(height: 12),
              _DashCard(
                d: d,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: d.bgTertiary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: d.borderColor),
                      ),
                      alignment: Alignment.center,
                      child: Text(activity.category.isEmpty ? '🎯' : '🎨', style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.providerBusinessName ?? 'Provider',
                            style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: d.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.verified_outlined, size: 16, color: d.accentBlue),
                              const SizedBox(width: 6),
                              Text(
                                activity.approvalStatus == 'approved' ? 'Listed on KiddoMarket' : activity.approvalStatus,
                                style: GoogleFonts.dmSans(fontSize: 12, color: d.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDesktopBook) ...[
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Starting from', style: DashboardTextStyles.label(d)),
              const SizedBox(height: 4),
              Text(
                price ?? 'Ask provider',
                style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w800, color: d.accentBlue),
              ),
              if ((priceSubtitle ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(priceSubtitle ?? '', style: DashboardTextStyles.cardSubtitle(d)),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => onPrimaryCta(),
                style: FilledButton.styleFrom(
                  backgroundColor: d.accentBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(196, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Contact provider', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BentoInfoGrid extends StatelessWidget {
  const _BentoInfoGrid({required this.d, required this.activity, required this.priceLine});

  final DashboardTokens d;
  final Activity activity;
  final String priceLine;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, IconData)>[
      ('Age range', '${activity.ageRangeMin}–${activity.ageRangeMax} yrs', Icons.cake_outlined),
      ('Category', activity.category.isEmpty ? '—' : activity.category, Icons.category_outlined),
      ('City', activity.city.isEmpty ? '—' : activity.city, Icons.place_outlined),
      ('Pricing', priceLine, Icons.payments_outlined),
    ];

    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width >= 768 ? 4 : 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [for (final it in items) _InfoTile(d: d, title: it.$1, value: it.$2, icon: it.$3)],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.d, required this.title, required this.value, required this.icon});

  final DashboardTokens d;
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      d: d,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: d.metricBlueBg.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: d.accentBlue, size: 20),
          ),
          const SizedBox(height: 10),
          Text(title, style: DashboardTextStyles.cardSubtitle(d), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: d.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  const _DashCard({required this.d, required this.child, this.padding});

  final DashboardTokens d;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: d.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: d.borderColor),
      ),
      child: child,
    );
  }
}

class _LeftColumn extends StatelessWidget {
  const _LeftColumn({required this.d, required this.activity});

  final DashboardTokens d;
  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('About', style: DashboardTextStyles.pageTitle(d)),
        const SizedBox(height: 10),
        Text(
          activity.description.isEmpty ? 'No description provided yet.' : activity.description,
          style: DashboardTextStyles.body(d).copyWith(height: 1.45),
        ),
        const SizedBox(height: 16),
        Wrap(
          runSpacing: 10,
          spacing: 16,
          children: [
            _CheckLine(d: d, text: 'Questions? Message the provider'),
            _CheckLine(d: d, text: 'Hosted by a verified listing'),
          ],
        ),
        const SizedBox(height: 22),
        Text('Location', style: DashboardTextStyles.pageTitle(d)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: d.bgTertiary),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.45,
                    child: Image.network(
                      'https://images.unsplash.com/photo-1526779259212-939e64788e3b?auto=format&fit=crop&w=1600&q=80',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                Center(
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: d.accentBlue,
                    child: Icon(Icons.location_on_rounded, color: Colors.white.withValues(alpha: 0.95)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _DashCard(
          d: d,
          padding: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Icon(Icons.near_me_outlined, color: d.accentBlue),
            title: Text(activity.city.isEmpty ? 'City not set' : activity.city, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: d.textSecondary)),
            subtitle: Text('Exact address shared by the provider.', style: DashboardTextStyles.cardSubtitle(d)),
          ),
        ),
      ],
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({required this.d, required this.text});

  final DashboardTokens d;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, color: d.statusApprovedText, size: 20),
        const SizedBox(width: 8),
        Text(text, style: DashboardTextStyles.body(d)),
      ],
    );
  }
}

class _RightColumn extends StatelessWidget {
  const _RightColumn({required this.d, required this.activity, required this.onContact});

  final DashboardTokens d;
  final Activity activity;
  final Future<void> Function() onContact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProviderCard(d: d, activity: activity, onContact: onContact),
        const SizedBox(height: 12),
        _ListingMetaCard(d: d, activity: activity),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.d, required this.activity, required this.onContact});

  final DashboardTokens d;
  final Activity activity;
  final Future<void> Function() onContact;

  @override
  Widget build(BuildContext context) {
    final snippet = activity.description.trim();
    final quote = snippet.length > 160 ? '${snippet.substring(0, 157)}…' : (snippet.isEmpty ? 'Tap below to ask questions about times, age groups, or pricing.' : snippet);

    return _DashCard(
      d: d,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: d.bgTertiary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: d.borderColor),
                ),
                child: Icon(Icons.storefront_outlined, color: d.textMuted, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.providerBusinessName ?? 'Provider',
                      style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: d.textPrimary),
                    ),
                    Text('Opens inquiries on KiddoMarket', style: DashboardTextStyles.cardSubtitle(d)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            quote,
            style: GoogleFonts.dmSans(fontSize: 13, height: 1.4, color: d.textMuted, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => onContact(),
            style: OutlinedButton.styleFrom(
              foregroundColor: d.accentBlue,
              side: BorderSide(color: d.borderColor),
              backgroundColor: d.bgPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: Icon(Icons.chat_bubble_outline_rounded, size: 18, color: d.accentBlue),
            label: Text('Contact provider', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ListingMetaCard extends StatelessWidget {
  const _ListingMetaCard({required this.d, required this.activity});

  final DashboardTokens d;
  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      d: d,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: d.metricAmberBg, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text('📅', style: TextStyle(fontSize: 13))),
              ),
              const SizedBox(width: 8),
              Text('Listing activity', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: d.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          _MetaRow(d: d, label: 'Views', value: '${activity.viewCount}'),
          const SizedBox(height: 8),
          _MetaRow(d: d, label: 'Inquiries', value: '${activity.inquiryCount}'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: d.bgPrimary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: d.borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: d.textFaint),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Schedule and session dates are coordinated directly with the provider after you send an inquiry.',
                    style: DashboardTextStyles.cardSubtitle(d).copyWith(height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.d, required this.label, required this.value});

  final DashboardTokens d;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: DashboardTextStyles.label(d))),
        Text(value, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: d.textSecondary)),
      ],
    );
  }
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.d, required this.activityId});

  final DashboardTokens d;
  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(activityApprovedReviewsProvider(activityId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Reviews', style: DashboardTextStyles.pageTitle(d))),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: d.bgSecondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: d.borderColor)),
                    content: Text('Reviews after visits — coming soon.', style: TextStyle(color: d.textSecondary)),
                  ),
                );
              },
              child: Text('Write a review', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: d.accentBlue)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        reviewsAsync.when(
          loading: () => LinearProgressIndicator(color: d.accentBlue, minHeight: 3, borderRadius: BorderRadius.circular(99)),
          error: (e, st) => Text('Could not load reviews.', style: TextStyle(color: d.statusRejectedText)),
          data: (items) {
            if (items.isEmpty) {
              return _DashCard(
                d: d,
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No approved reviews yet.',
                    style: DashboardTextStyles.body(d),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
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
                  childAspectRatio: cols == 2 ? 2.05 : 2.35,
                  children: [for (final r in items) _ReviewCard(d: d, r: r)],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          'Only approved reviews are shown.',
          style: DashboardTextStyles.cardSubtitle(d),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.d, required this.r});

  final DashboardTokens d;
  final Review r;

  @override
  Widget build(BuildContext context) {
    final initials = r.parentName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    final body = (r.reviewText ?? '').trim();
    final preview = body.isEmpty ? 'Rated this activity.' : body;

    return _DashCard(
      d: d,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: d.accentBlueBg,
                child: Text(initials.isEmpty ? '?' : initials, style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 11, color: d.roleParentText)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.parentName, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13, color: d.textSecondary)),
                    Text('Parent', style: DashboardTextStyles.cardSubtitle(d)),
                  ],
                ),
              ),
              _Stars(d: d, rating: r.rating.clamp(0, 5)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            preview,
            style: DashboardTextStyles.body(d).copyWith(color: d.textMuted, height: 1.35),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.d, required this.rating});

  final DashboardTokens d;
  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return Icon(filled ? Icons.star_rounded : Icons.star_border_rounded, size: 17, color: d.starColor);
      }),
    );
  }
}
