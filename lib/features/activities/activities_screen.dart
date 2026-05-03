import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/dashboard_tokens.dart';
import '../dashboards/parent/parent_nav.dart';
import 'activity_providers.dart';
import 'activity.dart';
import 'discover_filters_panel.dart';
import 'widgets/activity_network_image.dart';

/// Max width for discover column (sidebar is separate).
double _discoverMaxWidth(double paneWidth) {
  if (paneWidth >= 1280) return 960;
  if (paneWidth >= 1100) return 880;
  if (paneWidth >= 900) return 780;
  if (paneWidth >= parentNavBreakpoint) return math.min(paneWidth - 40, 720);
  return paneWidth;
}

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesFeedProvider);
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < parentNavBreakpoint;
    final maxW = _discoverMaxWidth(w);
    final hPad = isMobile ? 10.0 : 12.0;

    Widget constrained(Widget child) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: child,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        constrained(
          DiscoverFiltersPanel(
            compactHorizontal: isMobile,
            densePills: !isMobile,
          ),
        ),
        Expanded(
          child: constrained(
            activitiesAsync.when(
              loading: () => Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator(color: context.dash.accentBlue)),
              ),
              error: (e, st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load activities.\n$e',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.dash.textSecondary),
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No activities match your filters.\nTry another city or category.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          height: 1.4,
                          color: context.dash.textMuted,
                        ),
                      ),
                    ),
                  );
                }
                final bottomPad = parentContentBottomPadding(context);

                if (w >= 880) {
                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(0, 6, 0, bottomPad),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.35,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) => _ActivityFeedCard(activity: items[i], dense: true),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(0, 6, 0, bottomPad),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _ActivityFeedCard(activity: items[i], dense: false),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

bool _hasThumb(Activity a) => a.thumbnailUrl != null && a.thumbnailUrl!.trim().isNotEmpty;

class _ActivityFeedCard extends StatelessWidget {
  const _ActivityFeedCard({required this.activity, required this.dense});

  final Activity activity;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final d = context.dash;
    final pad = dense ? 10.0 : 11.0;

    return Material(
      color: d.bgSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: d.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/parent/discover/activity/${activity.id}'),
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ActivityListThumb(activity: activity, d: d, size: dense ? 56 : 60),
              SizedBox(width: dense ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title.isEmpty ? '(Untitled)' : activity.title,
                      style: GoogleFonts.dmSans(
                        fontSize: dense ? 14 : 14.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: d.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((activity.providerBusinessName ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        activity.providerBusinessName!.trim(),
                        style: GoogleFonts.dmSans(fontSize: 11.5, color: d.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        _ActivityListMetaChip(icon: Icons.place_outlined, text: activity.city, d: d),
                        _ActivityListMetaChip(icon: Icons.category_outlined, text: activity.category, d: d),
                        _ActivityListMetaChip(
                          icon: Icons.cake_outlined,
                          text: '${activity.ageRangeMin}–${activity.ageRangeMax} yrs',
                          d: d,
                        ),
                        if (activity.priceAmount != null)
                          _ActivityListMetaChip(
                            icon: Icons.euro_symbol,
                            text: '${activity.priceAmount}',
                            d: d,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityListThumb extends StatelessWidget {
  const _ActivityListThumb({required this.activity, required this.d, required this.size});

  final Activity activity;
  final DashboardTokens d;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (_hasThumb(activity)) {
      return ActivityNetworkImage(
        url: activity.thumbnailUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: d.bgTertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: d.borderColor.withValues(alpha: 0.65)),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.interests_outlined, size: size * 0.42, color: d.textMuted.withValues(alpha: 0.85)),
    );
  }
}

class _ActivityListMetaChip extends StatelessWidget {
  const _ActivityListMetaChip({
    required this.icon,
    required this.text,
    required this.d,
  });

  final IconData icon;
  final String text;
  final DashboardTokens d;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: d.bgTertiary.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: d.borderColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: d.textMuted),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: d.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
